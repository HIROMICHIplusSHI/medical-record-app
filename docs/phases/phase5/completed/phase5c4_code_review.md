# Phase 5-C-4: 同意書PDF出力機能 - コードレビュー結果

**レビュー日**: 2025-10-19
**レビュアー**: root-cause-analyst (Claude Code Agent)
**PR**: #22 - Phase 5-C-4: 同意書PDF出力機能
**ブランチ**: feature/p5c4-consent-pdf-output

---

## 1. 総合評価

**評価**: ⭐⭐⭐⭐ (4/5) - Good

**総評**:
全体的に高品質な実装です。既存のInvoicePdfGeneratorとの一貫性が高く、テストカバレッジも十分です。セキュリティ対策も適切に施されており、医療系アプリケーションとしての基本要件を満たしています。ただし、いくつかの改善点と潜在的なリスクが存在します。

### 品質スコア詳細

| 評価項目 | スコア | 備考 |
|---------|--------|------|
| **セキュリティ** | 85/100 | パストラバーサル対策済み、いくつか改善の余地あり |
| **パフォーマンス** | 90/100 | N+1対策済み、ファイルI/O最適化の余地あり |
| **コード品質** | 90/100 | テスト充実、小さな問題が1件 |
| **アーキテクチャ** | 95/100 | 既存パターンとの一貫性が高い |
| **医療特有考慮** | 80/100 | スナップショット対応済み、改ざん防止は今後の課題 |

---

## 2. 発見事項

### 🔴 Critical（即修正必要）

#### C-1: テスト失敗の存在

**問題**: Request Spec で1件のテスト失敗

**詳細**:
- ファイル: `spec/requests/patient_consents_spec.rb:327`
- テスト名: "新しい順に表示される"
- 原因: HTMLレスポンス内でのID文字列の位置比較が不安定（IDが文字列として複数箇所に出現）

**影響**: CI失敗によりマージブロック

**修正提案**:
```ruby
# spec/requests/patient_consents_spec.rb:327-332

# ❌ 修正前（不安定）
expect(response.body.index(patient_consent1.id.to_s)).to be < response.body.index(patient_consent2.id.to_s)

# ✅ 修正後（安定）
# @patient_consents の順序を直接確認
assigns(:patient_consents).tap do |consents|
  expect(consents.first).to eq(patient_consent1)
  expect(consents.second).to eq(patient_consent2)
end

# または Capybara パーサー使用
parsed = Capybara.string(response.body)
consent_elements = parsed.all('.bg-white.shadow-md')
expect(consent_elements.first).to have_link('詳細', href: medical_record_patient_consent_path(@medical_record, patient_consent1))
expect(consent_elements.last).to have_link('詳細', href: medical_record_patient_consent_path(@medical_record, patient_consent2))
```

---

#### C-2: ファイル削除時のエラーハンドリング不足

**問題**: `destroy` アクションでのPDF削除が無条件に成功扱い

**詳細**:
- ファイル: `app/controllers/patient_consents_controller.rb:90-97`
- `FileUtils.rm_f` は失敗を報告しない

**影響**:
- ディスク容量の無駄（孤立ファイル）
- 監査証跡の欠落

**修正提案**:
```ruby
# app/controllers/patient_consents_controller.rb:90-97

def destroy
  pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{@patient_consent.id}.pdf")

  # ファイル削除をログに記録
  if File.exist?(pdf_path)
    FileUtils.rm_f(pdf_path)
    Rails.logger.info "Deleted PDF file: #{pdf_path} (consent_id: #{@patient_consent.id})"
  end

  @patient_consent.destroy
  redirect_to medical_record_path(@medical_record), notice: '同意書を削除しました。'
end
```

---

### 🟡 Warning（改善推奨）

#### W-1: Brakeman警告 - パストラバーサル（Weak）

**問題**: `params[:id]` がファイルパスに使用されている

**詳細**:
- ファイル: `app/controllers/patient_consents_controller.rb`
- 箇所:
  - `download_pdf` (L66): `send_file` でのパス構築
  - `destroy` (L93): `FileUtils.rm_f` でのパス構築

**現状の対策**:
- ✅ `current_user.medical_records.find(params[:medical_record_id])` で認可チェック
- ✅ `.patient_consents.find(params[:id])` でスコープ制限
- ✅ `sanitize_filename` でファイル名サニタイズ

**追加対策提案**:
```ruby
# app/controllers/patient_consents_controller.rb

private

# IDの整数性を保証
def validate_consent_id
  Integer(params[:id])
rescue ArgumentError, TypeError
  raise ActiveRecord::RecordNotFound
end

# PDFパスの構築を一元化
def pdf_path_for(consent)
  validate_consent_id # 追加
  pdf_dir = Rails.root.join('tmp', 'pdfs')
  pdf_filename = "patient_consent_#{consent.id}.pdf" # consent.id は整数確定

  # パスの正規化と検証
  full_path = pdf_dir.join(pdf_filename).cleanpath

  # ディレクトリトラバーサル防止
  unless full_path.to_s.start_with?(pdf_dir.to_s)
    raise ArgumentError, "Invalid file path"
  end

  full_path
end

# 使用例
def download_pdf
  pdf_path = pdf_path_for(@patient_consent)

  unless File.exist?(pdf_path)
    redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
                alert: 'PDFが生成されていません。先にPDF生成を実行してください。'
    return
  end

  send_file pdf_path,
            type: 'application/pdf',
            disposition: 'attachment',
            filename: sanitize_filename("patient_consent_#{@patient_consent.id}.pdf")
end
```

---

#### W-2: PDF生成の冪等性問題

**問題**: `generate_pdf` を複数回実行すると毎回上書き

**詳細**:
- タイムスタンプなし = 同じファイル名で上書き
- 生成履歴が残らない

**影響**:
- 証拠保全の観点で問題（いつ生成したか不明）
- 複数バージョンの保持ができない

**修正提案**:
```ruby
# app/services/patient_consent_pdf_generator.rb:234-242

def save_pdf
  pdf_dir = Rails.root.join('tmp', 'pdfs')
  FileUtils.mkdir_p(pdf_dir) unless File.directory?(pdf_dir)

  # タイムスタンプ付きファイル名（証拠保全）
  timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
  pdf_path = pdf_dir.join("patient_consent_#{@consent.id}_#{timestamp}.pdf")

  @pdf.render_file(pdf_path)

  # 最新のシンボリックリンクを作成（既存コードとの互換性）
  latest_link = pdf_dir.join("patient_consent_#{@consent.id}.pdf")
  FileUtils.rm_f(latest_link) if File.exist?(latest_link) || File.symlink?(latest_link)
  FileUtils.ln_s(pdf_path, latest_link)

  pdf_path.to_s
end
```

**Phase 5-C-5での対応案**:
```ruby
# マイグレーション
add_column :patient_consents, :pdf_generated_at, :datetime

# PatientConsent モデル
after_update :invalidate_pdf_cache, if: :saved_change_to_signature_data?

private

def invalidate_pdf_cache
  self.pdf_generated_at = nil
end
```

---

#### W-3: メモリ使用量の最適化余地

**問題**: `generate_to_string` でPDF全体をメモリに展開

**詳細**:
- 署名画像が大きい場合（最大2MB）、メモリ圧迫
- 同時プレビューが多いと問題

**影響**: パフォーマンス低下（高負荷時）

**修正提案**:
```ruby
# app/controllers/patient_consents_controller.rb:73-87

def preview_pdf
  # ストリーミング方式でメモリ効率化
  pdf_path = pdf_path_for(@patient_consent)

  # 既存PDFがあればそれを使用（再生成不要）
  if File.exist?(pdf_path) && File.mtime(pdf_path) > @patient_consent.updated_at
    send_file pdf_path,
              type: 'application/pdf',
              disposition: 'inline',
              filename: sanitize_filename("preview_patient_consent_#{@patient_consent.id}.pdf")
    return
  end

  # 新規生成時のみ generate_to_string
  generator = PatientConsentPdfGenerator.new(@patient_consent)
  pdf_content = generator.generate_to_string

  send_data pdf_content,
            type: 'application/pdf',
            disposition: 'inline',
            filename: sanitize_filename("preview_patient_consent_#{@patient_consent.id}.pdf")
rescue StandardError => e
  Rails.logger.error "PDF Preview Error: #{e.class}: #{e.message}"
  Rails.logger.error e.backtrace.first(10).join("\n")
  render plain: "PDF生成中にエラーが発生しました: #{e.message}", status: :internal_server_error
end
```

---

#### W-4: エラーメッセージの情報漏洩リスク

**問題**: 例外メッセージがそのままユーザーに表示される

**詳細**:
- `generate_pdf` (L51): `alert: "PDF生成中にエラーが発生しました: #{e.message}"`
- `preview_pdf` (L86): `render plain: "PDF生成中にエラーが発生しました: #{e.message}"`

**影響**: 内部構造の露出（セキュリティ）

**修正提案**:
```ruby
# app/controllers/patient_consents_controller.rb

def generate_pdf
  PatientConsentPdfGenerator.new(@patient_consent).generate
  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              notice: 'PDFを生成しました。'
rescue StandardError => e
  Rails.logger.error "PDF Generation Error: #{e.class}: #{e.message}"
  Rails.logger.error e.backtrace.first(10).join("\n")

  # 本番環境ではジェネリックなエラーメッセージ
  error_message = if Rails.env.production?
    'PDF生成中にエラーが発生しました。管理者にお問い合わせください。'
  else
    "PDF生成中にエラーが発生しました: #{e.message}"
  end

  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              alert: error_message
end
```

---

#### W-5: 署名画像のバリデーションが実行時点のみ

**問題**: PDF生成時に署名データが不正でもスキップ

**詳細**:
- ファイル: `app/services/patient_consent_pdf_generator.rb:190-212`
- エラーを握りつぶして "署名画像の読み込みに失敗しました" と表示

**影響**:
- ユーザーが気づかない可能性
- 無効なPDFが生成される

**修正提案**:
```ruby
# app/services/patient_consent_pdf_generator.rb:26-33

def generate_to_string
  # 署名データの事前検証
  unless @consent.signature_data.present? && valid_signature?
    raise ArgumentError, "Invalid signature data for consent ID: #{@consent.id}"
  end

  build_consent_title
  build_consent_items
  build_signature
  build_facility_info

  @pdf.render
end

# コントローラーでのエラーハンドリング強化
def generate_pdf
  PatientConsentPdfGenerator.new(@patient_consent).generate
  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              notice: 'PDFを生成しました。'
rescue ArgumentError => e
  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              alert: '署名データが不正です。同意書を再作成してください。'
rescue StandardError => e
  Rails.logger.error "PDF Generation Error: #{e.class}: #{e.message}"
  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              alert: 'PDF生成中にエラーが発生しました。'
end
```

---

#### W-6: UIの改善余地（詳細画面）

**問題**: PDF生成→ダウンロードの2ステップが冗長

**詳細**: `app/views/patient_consents/show.html.erb:121-134`

**影響**: UX低下

**修正提案**:
```erb
<!-- app/views/patient_consents/show.html.erb -->
<div class="px-6 py-5">
  <div class="flex flex-wrap gap-4">
    <!-- オンデマンド生成ダウンロード -->
    <%= link_to 'PDFダウンロード',
        download_pdf_medical_record_patient_consent_path(@medical_record, @patient_consent, auto_generate: true),
        class: 'inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500' %>

    <%= link_to 'PDFプレビュー',
        preview_pdf_medical_record_patient_consent_path(@medical_record, @patient_consent),
        target: '_blank',
        class: 'inline-flex items-center px-6 py-3 border border-gray-300 text-base font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500' %>
  </div>

  <p class="mt-4 text-sm text-gray-500">
    ※ PDFは初回ダウンロード時に自動生成されます。
  </p>
</div>
```

```ruby
# app/controllers/patient_consents_controller.rb

def download_pdf
  pdf_path = pdf_path_for(@patient_consent)

  # PDFファイルがない、または同意書が更新された場合は自動生成
  if !File.exist?(pdf_path) || (params[:auto_generate] && File.mtime(pdf_path) < @patient_consent.updated_at)
    PatientConsentPdfGenerator.new(@patient_consent).generate
  end

  send_file pdf_path,
            type: 'application/pdf',
            disposition: 'attachment',
            filename: sanitize_filename("patient_consent_#{@patient_consent.id}.pdf")
rescue StandardError => e
  Rails.logger.error "PDF Download Error: #{e.class}: #{e.message}"
  redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
              alert: 'PDFのダウンロードに失敗しました。'
end
```

---

### 🟢 Info（参考情報）

#### I-1: テストの改善余地

**観点**: Service Specでのテキスト抽出

**詳細**: `spec/services/patient_consent_pdf_generator_spec.rb:48-58`

**現状**: ファイルサイズのみで検証（内容は未検証）

**改善提案**:
```ruby
# Gemfile に追加
group :test do
  gem 'pdf-reader'
end

# spec/services/patient_consent_pdf_generator_spec.rb
it '生成されたPDFに期待される内容が含まれる' do
  generator = described_class.new(consent)
  pdf_string = generator.generate_to_string

  # PDF::Reader を使用したテキスト抽出
  require 'pdf/reader'
  io = StringIO.new(pdf_string)
  reader = PDF::Reader.new(io)

  text = reader.pages.map(&:text).join("\n")

  expect(text).to include(consent.consent_form_template.title)
  expect(text).to include(consent.patient.name)
  expect(text).to include(consent.facility_name)
  expect(text).to include('同意日')
end
```

---

#### I-2: ログ出力の充実

**観点**: 監査証跡の強化

**詳細**: PDF生成・ダウンロード・削除の履歴

**改善提案**:
```ruby
# app/controllers/patient_consents_controller.rb

after_action :log_pdf_action, only: [:generate_pdf, :download_pdf, :preview_pdf]

private

def log_pdf_action
  return unless performed?

  action_type = case action_name
                when 'generate_pdf' then 'GENERATION'
                when 'download_pdf' then 'DOWNLOAD'
                when 'preview_pdf' then 'PREVIEW'
                end

  Rails.logger.info "[PDF_#{action_type}] user_id: #{current_user.id}, " \
                    "consent_id: #{@patient_consent.id}, " \
                    "patient_id: #{@patient_consent.patient_id}, " \
                    "timestamp: #{Time.current.iso8601}"
end
```

---

#### I-3: パフォーマンス計測の推奨

**観点**: PDF生成時間の監視

**詳細**: 署名画像が大きい場合のレイテンシー

**改善提案**:
```ruby
# app/services/patient_consent_pdf_generator.rb

def generate
  start_time = Time.current

  build_consent_title
  build_consent_items
  build_signature
  build_facility_info

  pdf_path = save_pdf

  elapsed = Time.current - start_time
  Rails.logger.info "[PDF_GENERATION_PERFORMANCE] consent_id: #{@consent.id}, elapsed: #{elapsed.round(3)}s"

  pdf_path
end
```

---

#### I-4: 日本語フォント未導入時の対応

**観点**: フォントがない環境での挙動

**詳細**: `setup_fonts` (L37-52) が失敗してもフォールバック

**現状**: 問題なし（警告ログ出力）

**改善提案**: 開発環境でのフォントチェック追加
```ruby
# lib/tasks/system_check.rake

namespace :system do
  desc 'Check required fonts for PDF generation'
  task check_fonts: :environment do
    font_path = Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf')

    if File.exist?(font_path)
      puts "✓ Japanese font found: #{font_path}"
    else
      puts "✗ Japanese font NOT found: #{font_path}"
      puts "  Please download Noto Sans JP from https://fonts.google.com/noto/specimen/Noto+Sans+JP"
      exit 1
    end
  end
end

# CI/CDに追加
# .github/workflows/ci.yml
# - name: Check fonts
#   run: bundle exec rake system:check_fonts
```

---

## 3. 良い点（評価できる実装）

### ✅ アーキテクチャ

#### 1. 既存パターンとの高い一貫性

- InvoicePdfGenerator と同じ構造（`generate` / `generate_to_string`）
- フォント設定、エラーハンドリングが統一
- 将来的なリファクタリングの基盤ができている

#### 2. 責務分離の徹底

- Service クラスがPDF生成ロジックをカプセル化
- Controller は薄く保たれている
- View は表示のみに専念

---

### ✅ セキュリティ

#### 3. 適切な認可チェック

- `set_medical_record` で `current_user.medical_records.find`
- `set_patient_consent` で `@medical_record.patient_consents.find`
- 他ユーザーのデータにアクセス不可

#### 4. 個人情報の暗号化対応

- `PatientConsent` モデルで署名・施設情報を暗号化
- Active Record Encryption による保護

#### 5. ファイル名のサニタイズ

- `sanitize_filename` メソッドによる対策
- 正規表現で危険な文字を除去

---

### ✅ パフォーマンス

#### 6. N+1クエリ対策の徹底

- `set_patient_consent` で `includes` 使用
- `index` アクションでも `includes` 適用
- 関連データを一括取得

#### 7. Eager Loading の適切性

```ruby
@patient_consent = @medical_record.patient_consents
  .includes(
    :patient,
    :consent_form_template,
    :facility_doctor,
    consent_item_responses: :consent_form_item
  )
  .find(params[:id])
```

---

### ✅ テストカバレッジ

#### 8. 包括的なテスト

- Service Spec: 12 examples（PDF生成、エラーハンドリング）
- Request Spec: 7 examples追加（CRUD、認証・認可）
- System Spec: 2 examples追加（E2E、削除フロー）

#### 9. エッジケースの考慮

- 不正な署名データでのPDF生成継続（Service Spec）
- 未ログイン時のリダイレクト（Request Spec）
- 他ユーザーのデータアクセス防止（Request Spec）

---

### ✅ コード品質

#### 10. RuboCop準拠

- 107 files, no offenses
- `.rubocop.yml` での適切な例外設定

#### 11. 命名規則の一貫性

- メソッド名が明確（`generate_pdf`, `download_pdf`, `preview_pdf`）
- 変数名がわかりやすい（`@patient_consent`, `pdf_path`）

#### 12. コメントの適切性

- 日本語コメントで意図を明示
- 複雑なロジックに説明追加

---

### ✅ 医療系アプリケーション特有の考慮

#### 13. スナップショット機能の実装

- `before_create :snapshot_facility_info`
- 施設情報・施術者名を同意書作成時に保存
- テンプレート変更の影響を受けない

#### 14. 改行対応

- `whitespace-pre-line` でテンプレート説明文の改行を反映
- 同意項目の内容も改行対応

#### 15. 署名データのバリデーション

- フォーマット検証（Base64 PNG）
- サイズ検証（最大2MB）
- 内容検証（PNGマジックナンバー、最小サイズ）

---

## 4. Phase 5-C-5への提言

### 🎯 必須対応事項（PR本文でも言及済み）

#### 1. 同意書テンプレート内容のスナップショット化

**背景**: 現状、テンプレート編集後に過去の同意書も変更されてしまう

**実装内容**:
```ruby
# マイグレーション
class AddSnapshotToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :template_title, :string
    add_column :consent_item_responses, :item_content, :text
  end
end

# PatientConsent モデル
before_create :snapshot_template_content

def snapshot_template_content
  self.template_title = consent_form_template.title
end

# ConsentItemResponse モデル
before_create :snapshot_item_content

def snapshot_item_content
  self.item_content = consent_form_item.content
end
```

**PDF生成の変更**:
```ruby
# app/services/patient_consent_pdf_generator.rb

def build_consent_title
  # 変更前: @template.title
  # 変更後: @consent.template_title
  @pdf.text @consent.template_title, size: 18, style: :bold, align: :center
  # ...
end

def build_consent_items_data
  items = @consent.consent_item_responses.includes(:consent_form_item).order('consent_form_items.position')

  items.map do |response|
    check_mark = response.checked ? '[✓]' : '[ ]'
    [check_mark, response.item_content] # スナップショット値を使用
  end
end
```

---

#### 2. 看護師確認フロー追加

**背景**: 医療現場のダブルチェック体制

**実装内容**:
```ruby
# マイグレーション
class AddNurseConfirmationToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :nurse_confirmed, :boolean, default: false
    add_column :patient_consents, :nurse_confirmed_at, :datetime
    add_column :patient_consents, :nurse_id, :bigint
    add_foreign_key :patient_consents, :users, column: :nurse_id
  end
end

# PatientConsent モデル
belongs_to :nurse, class_name: 'User', optional: true
validates :nurse_confirmed, inclusion: { in: [true, false] }

# UI変更（Step 2）
# 1. 患者が署名
# 2. 看護師確認チェックボックス追加
# 3. 確認後に「同意する」ボタンを有効化
```

**View変更案**:
```erb
<!-- app/views/patient_consents/new.html.erb Step 2 -->

<!-- 署名エリアの直後に追加 -->
<div class="mt-6 bg-yellow-50 border-l-4 border-yellow-400 p-4">
  <p class="text-sm text-yellow-800">
    署名が終わりましたら、担当看護師が確認いたしますので、しばらく今の状態でお待ちいただくか、
    再度内容をご確認ください。別途書類を発行いたします。
  </p>
</div>

<div class="mt-4">
  <label class="flex items-center">
    <%= check_box_tag "patient_consents[#{index}][nurse_confirmed]", "1", false,
        data: { consent_forms_target: "nurseCheckbox" },
        class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" %>
    <span class="ml-2 text-sm font-medium text-gray-900">
      看護師確認済み（看護師のみチェックしてください）
    </span>
  </label>
</div>
```

---

#### 3. 署名漏れ時のバリデーション改善

**背景**: Step 2で署名なしでエラー時に情報が失われる

**実装内容**:
```javascript
// app/javascript/controllers/consent_forms_controller.js

validateSignature() {
  const signatureCanvas = this.element.querySelector('[data-signature-target="canvas"]');
  const signatureData = this.element.querySelector('[data-signature-target="hiddenField"]').value;

  if (!signatureData || signatureData === '') {
    this.showError('署名が必要です。上記のキャンバスに署名してください。');
    signatureCanvas.scrollIntoView({ behavior: 'smooth', block: 'center' });
    return false;
  }
  return true;
}

showError(message) {
  const errorDiv = document.createElement('div');
  errorDiv.className = 'bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4';
  errorDiv.textContent = message;

  const step2Content = this.step2ContentTarget;
  step2Content.insertBefore(errorDiv, step2Content.firstChild);

  setTimeout(() => errorDiv.remove(), 5000);
}

submitForm(event) {
  if (!this.validateSignature()) {
    event.preventDefault();
    return false;
  }

  // 看護師確認チェック
  const nurseCheckbox = this.element.querySelector('[data-consent-forms-target="nurseCheckbox"]');
  if (nurseCheckbox && !nurseCheckbox.checked) {
    event.preventDefault();
    this.showError('看護師の確認が必要です。');
    return false;
  }
}
```

---

### 🔒 セキュリティ強化（推奨）

#### 4. PDF改ざん防止

**背景**: 法的証拠性の確保

**実装内容**:
```ruby
# マイグレーション
class AddPdfHashToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :pdf_hash, :string
  end
end

# PatientConsent モデル
after_create :generate_pdf_hash

def generate_pdf_hash
  pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{id}.pdf")
  return unless File.exist?(pdf_path)

  self.pdf_hash = Digest::SHA256.file(pdf_path).hexdigest
  save
end

# 検証メソッド
def verify_pdf_integrity
  pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{id}.pdf")
  return false unless File.exist?(pdf_path)

  current_hash = Digest::SHA256.file(pdf_path).hexdigest
  current_hash == pdf_hash
end
```

---

#### 5. PDFファイルの保存期間管理

**背景**: ディスク容量の管理

**実装内容**:
```ruby
# lib/tasks/pdf_cleanup.rake

namespace :pdf do
  desc 'Clean up old PDF files (older than 30 days)'
  task cleanup: :environment do
    pdf_dir = Rails.root.join('tmp', 'pdfs')
    retention_days = ENV.fetch('PDF_RETENTION_DAYS', 30).to_i
    cutoff_date = retention_days.days.ago

    deleted_count = 0

    Dir.glob(pdf_dir.join('*.pdf')).each do |file|
      if File.mtime(file) < cutoff_date
        FileUtils.rm_f(file)
        deleted_count += 1
        puts "Deleted: #{File.basename(file)} (modified: #{File.mtime(file)})"
      end
    end

    puts "Cleanup complete. Deleted #{deleted_count} files."
  rescue StandardError => e
    puts "Error during cleanup: #{e.message}"
    raise
  end
end

# config/schedule.rb (whenever gem)
every :sunday, at: '3:00 am' do
  rake 'pdf:cleanup'
end
```

---

### 📊 監視・運用（推奨）

#### 6. PDF生成エラーの監視

**背景**: 本番環境でのエラー検知

**実装内容**:
```ruby
# config/initializers/sentry.rb（Phase 6で導入予定）

Sentry.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.before_send = lambda do |event, hint|
    # PDF関連エラーを優先度高くタグ付け
    if event.exception&.backtrace&.any? { |line| line.include?('pdf_generator') }
      event.tags[:pdf_error] = true
      event.level = :error
      event.fingerprint = ['pdf-generation-error', event.exception.class.to_s]
    end
    event
  end
end
```

---

#### 7. パフォーマンス監視

**背景**: PDF生成時間の追跡

**実装内容**:
```ruby
# app/controllers/patient_consents_controller.rb

around_action :measure_pdf_performance, only: [:generate_pdf, :preview_pdf]

private

def measure_pdf_performance
  start_time = Time.current
  yield
  elapsed = Time.current - start_time

  Rails.logger.info "[PDF_PERFORMANCE] action: #{action_name}, " \
                    "consent_id: #{@patient_consent.id}, " \
                    "elapsed: #{elapsed.round(3)}s"

  # 5秒以上かかった場合は警告
  if elapsed > 5
    Rails.logger.warn "[PDF_SLOW_GENERATION] consent_id: #{@patient_consent.id}, " \
                      "elapsed: #{elapsed.round(3)}s, " \
                      "signature_size: #{@patient_consent.signature_data&.bytesize || 0}"
  end
end
```

---

## 5. 修正の優先順位

### マージ前に必須（Priority 1）

| # | 項目 | 重要度 | 工数 | 担当 |
|---|------|--------|------|------|
| C-1 | テスト失敗の修正 | 🔴 Critical | 10分 | すぐ対応 |
| C-2 | ファイル削除ログ追加 | 🔴 Critical | 5分 | すぐ対応 |
| W-1 | パストラバーサル対策明示化 | 🟡 Warning | 20分 | すぐ対応 |

**推定作業時間**: 35分

---

### マージ後すぐに対応（Priority 2）

| # | 項目 | 重要度 | 工数 | 担当 |
|---|------|--------|------|------|
| W-4 | エラーメッセージ環境別制御 | 🟡 Warning | 15分 | 別PR |
| I-2 | 監査ログ実装 | 🟢 Info | 30分 | 別PR |

**推定作業時間**: 45分

---

### Phase 5-C-5で対応（Priority 3）

| # | 項目 | 重要度 | 工数 | 担当 |
|---|------|--------|------|------|
| 必須1 | テンプレートスナップショット化 | 🔴 Critical | 2時間 | Phase 5-C-5 |
| 必須2 | 看護師確認フロー | 🔴 Critical | 3時間 | Phase 5-C-5 |
| 必須3 | 署名バリデーション改善 | 🔴 Critical | 1時間 | Phase 5-C-5 |
| W-2 | PDF生成タイムスタンプ化 | 🟡 Warning | 1時間 | Phase 5-C-5 |
| 推奨4 | PDF改ざん防止（ハッシュ） | 🟡 Warning | 1時間 | Phase 5-C-5 |

**推定作業時間**: 8時間

---

### Phase 6以降で対応（Priority 4）

| # | 項目 | 重要度 | 工数 | 担当 |
|---|------|--------|------|------|
| W-3 | メモリ最適化 | 🟢 Info | 1時間 | Phase 6 |
| W-6 | UX改善（ワンクリック） | 🟢 Info | 1時間 | Phase 6 |
| I-1 | PDFテキスト抽出テスト | 🟢 Info | 1時間 | Phase 6 |
| 推奨5 | PDF保存期間管理 | 🟢 Info | 1.5時間 | Phase 6 |
| 推奨6 | Sentry連携 | 🟢 Info | 2時間 | Phase 6 |
| 推奨7 | パフォーマンス監視 | 🟢 Info | 1時間 | Phase 6 |

**推定作業時間**: 7.5時間

---

## 6. まとめ

### マージ判定

**結論**: 🟡 **条件付きマージ可**

**条件**:
1. ✅ Priority 1（C-1, C-2, W-1）の修正完了
2. ✅ CI通過（RSpec, RuboCop, Brakeman）
3. ✅ 手動でのPDF生成・ダウンロード・削除の動作確認

**推奨アクション**:
1. Priority 1の修正を実施（35分）
2. CI通過確認
3. PRマージ
4. Priority 2を別PRで対応（45分）
5. Phase 5-C-5でスナップショット化・看護師フロー実装（8時間）

---

### 次フェーズへの引き継ぎ事項

**Phase 5-C-5で必ず対応**:
- ✅ テンプレート内容のスナップショット化（template_title, item_content）
- ✅ 看護師確認フロー実装
- ✅ 署名バリデーション改善
- ✅ PDF改ざん防止（ハッシュ値保存）

**Phase 6で検討**:
- メモリ最適化
- UX改善（ワンクリックダウンロード）
- PDF保存期間管理（自動削除）
- Sentry連携
- パフォーマンス監視

---

## 7. 参考資料

### 関連ドキュメント

- [Phase 5-C-4 実装計画](../overview.md)
- [Phase 5-C-5 計画](../phase5c5_consent_snapshot_plan.md)（作成予定）
- [データモデル設計](../../02_data_model.md)
- [テスト戦略](../../05_testing_strategy.md)

### 参考実装

- `app/services/invoice_pdf_generator.rb` - 請求書PDF生成（同様のパターン）
- `app/controllers/invoices_controller.rb` - PDF操作コントローラー
- `spec/services/invoice_pdf_generator_spec.rb` - PDFサービステスト

### 技術資料

- [Prawn PDF公式ドキュメント](https://prawnpdf.org/docs/)
- [Rails Active Record Encryption](https://guides.rubyonrails.org/active_record_encryption.html)
- [Brakeman セキュリティ警告](https://brakemanscanner.org/docs/warning_types/)

---

**レビュー完了日**: 2025-10-19
**次回レビュー**: Phase 5-C-5実装後
