# Phase 5-C: 同意書機能 - 実装計画

**作成日**: 2025-10-17
**推定工数**: 14-18日（約3週間）
**ステータス**: 📋 計画中

---

## 📋 概要

### 目的

フリーランスアートメイク施術者が患者から電子同意書を取得し、PDF化・保管できる機能を実装する。

### 解決する課題

- **紙の同意書管理**: 物理的な保管が必要 → デジタル化で効率化
- **同意書の種類**: 施術ごとに異なる同意書 → テンプレート化で柔軟対応
- **署名の取得**: 手書き署名が必要 → Canvas手書き署名で実現
- **医師情報の管理**: 施設ごとの担当医師 → 施設に医師情報を紐付け
- **法的証跡**: 同意の証拠を残す → IPアドレス、タイムスタンプ記録

---

## 🎯 機能要件

### 1. 施設医師情報管理

- 各施設に複数の医師を紐付け
- 医師名、医師免許番号、専門分野を管理
- 同意書作成時に施設に紐付く医師のみ選択可能

### 2. 同意書テンプレート管理

- ユーザーが複数の同意書テンプレートを作成
- テンプレートごとにカスタマイズ可能なチェック項目
- チェック項目の追加・削除・並び替え（ドラッグ&ドロップ）
- 必須項目の設定

### 3. 患者同意書作成・署名

- カルテ作成後に同意書を作成
- 複数の同意書テンプレートを選択可能
- 施設に紐付く医師をプルダウンから選択
- 施術者名を自動表示（ユーザー情報から）
- 施設情報を自動表示（カルテの施設情報から）
- Canvas手書き署名機能
- チェック項目の確認・チェック

### 4. 同意書PDF生成

- 日本語対応PDF生成（Prawn + Noto Sans JP）
- チェック項目の表示（☑/☐）
- 医師名、施術者名、施設情報の表示
- 署名画像の埋め込み
- 同意日時の表示
- PDFプレビュー・ダウンロード機能

### 5. セキュリティ・法的証跡

- Active Record Encryption による個人情報暗号化
- 署名時のIPアドレス記録
- 署名時のUser-Agent記録
- 施設情報のスナップショット保存（後からの変更に対応）

---

## 📊 データモデル設計

### ER図

```
User (施術者)
  |
  |-- has_many --> Facility (施設)
  |                   |
  |                   |-- has_many --> FacilityDoctor (医師情報) ★NEW
  |                   |
  |                   |-- has_many --> MedicalRecord (カルテ)
  |                                       |
  |-- has_many --> ConsentFormTemplate (同意書テンプレート) ★NEW
  |                   |
  |                   |-- has_many --> ConsentFormItem (チェック項目) ★NEW
  |                   |
  |                   |-- has_many --> PatientConsent (患者同意書) ★NEW
  |                                       |
  |                                       |-- belongs_to --> MedicalRecord
  |                                       |-- belongs_to --> FacilityDoctor
  |                                       |-- has_many --> ConsentItemResponse ★NEW
```

### 新規モデル（5モデル）

#### 1. FacilityDoctor（施設医師情報）

```ruby
# テーブル: facility_doctors
belongs_to :facility
has_many :patient_consents

# フィールド:
- facility_id: bigint (FK)
- name: string (医師名) NOT NULL
- medical_license_number: string (医師免許番号、任意)
- specialization: string (専門分野、任意)
- created_at, updated_at
```

#### 2. ConsentFormTemplate（同意書テンプレート）

```ruby
# テーブル: consent_form_templates
belongs_to :user
has_many :consent_form_items, dependent: :destroy
has_many :patient_consents
accepts_nested_attributes_for :consent_form_items

# フィールド:
- user_id: bigint (FK)
- title: string (例: "アートメイク施術同意書") NOT NULL
- description: text (説明文)
- is_active: boolean (使用中かどうか) DEFAULT true
- created_at, updated_at
```

#### 3. ConsentFormItem（チェック項目）

```ruby
# テーブル: consent_form_items
belongs_to :consent_form_template
has_many :consent_item_responses, dependent: :destroy

# フィールド:
- consent_form_template_id: bigint (FK)
- content: text (項目内容) NOT NULL
- position: integer (表示順序) NOT NULL
- is_required: boolean (必須項目) DEFAULT true
- created_at, updated_at
```

#### 4. PatientConsent（患者同意書）

```ruby
# テーブル: patient_consents
belongs_to :patient
belongs_to :consent_form_template
belongs_to :medical_record
belongs_to :facility_doctor
belongs_to :user
has_many :consent_item_responses, dependent: :destroy
has_one_attached :signature_image
accepts_nested_attributes_for :consent_item_responses

# フィールド（暗号化対象: signature_data, practitioner_name, facility_*）:
- patient_id: bigint (FK)
- consent_form_template_id: bigint (FK)
- medical_record_id: bigint (FK)
- facility_doctor_id: bigint (FK)
- user_id: bigint (FK)
- agreed_at: datetime (同意日時) NOT NULL
- signature_data: text (Canvas署名のBase64、暗号化)
- practitioner_name: text (施術者名、暗号化)
- facility_name: text (施設名スナップショット、暗号化)
- facility_address: text (施設住所スナップショット、暗号化)
- facility_phone: text (施設電話番号スナップショット、暗号化)
- signed_ip: string (署名時のIPアドレス)
- signed_user_agent: text (署名時のUser-Agent)
- created_at, updated_at
```

#### 5. ConsentItemResponse（チェック項目への回答）

```ruby
# テーブル: consent_item_responses
belongs_to :patient_consent
belongs_to :consent_form_item

# フィールド:
- patient_consent_id: bigint (FK)
- consent_form_item_id: bigint (FK)
- checked: boolean (チェック有無) DEFAULT false
- created_at, updated_at
```

---

## 🎨 UI/UX 設計

### 画面1: 施設編集画面（医師情報追加）

**パス**: `/facilities/:id/edit`

```
施設編集
├─ 施設名: [入力]
├─ 住所: [入力]
├─ 電話番号: [入力]
├─ メール: [入力]
├─ 請求先名: [入力]
├─ 請求割合: [入力]
└─ 【医師情報】
   ├─ [医師を追加] ボタン ← Stimulus
   ├─ 医師1:
   │  ├─ 医師名: [入力]
   │  ├─ 医師免許番号: [入力]（任意）
   │  ├─ 専門分野: [入力]（任意）
   │  └─ [削除]
   └─ 医師2: ...
```

**Stimulus Controller**: `nested-form-controller.js`

---

### 画面2: 同意書テンプレート一覧

**パス**: `/consent_form_templates`

```
同意書テンプレート一覧

[新規作成]

┌─────────────────────────────────────────┐
│ アートメイク施術同意書                    │
│ 使用中 | 項目: 5件                        │
│ [編集] [削除] [プレビュー]                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 麻酔同意書                               │
│ 使用中 | 項目: 3件                        │
│ [編集] [削除] [プレビュー]                │
└─────────────────────────────────────────┘
```

---

### 画面3: 同意書テンプレート作成・編集

**パス**: `/consent_form_templates/new`, `/consent_form_templates/:id/edit`

```
同意書テンプレート作成

タイトル: [入力] 例: "アートメイク施術同意書"
説明文: [テキストエリア]
[✓] 使用中

【チェック項目】
├─ [項目を追加] ボタン
├─ ☰ 項目1: ← ドラッグハンドル
│  ├─ 内容: [入力] "施術にはリスクがあることを理解しました"
│  ├─ [✓] 必須項目
│  └─ [削除]
├─ ☰ 項目2:
│  ├─ 内容: [入力] "アレルギーの有無を正しく申告しました"
│  ├─ [✓] 必須項目
│  └─ [削除]
└─ ...

[保存]
```

**Stimulus Controllers**:
- `nested-form-controller.js` (項目追加・削除)
- `sortable-controller.js` (ドラッグ&ドロップ並び替え)

**Gem追加**: `sortablejs-rails`

---

### 画面4: カルテ詳細画面（同意書セクション追加）

**パス**: `/medical_records/:id`

```
カルテ詳細 #123

【カルテ情報】
患者: 田中花子
施設: サロンA
施術日: 2024-01-15
合計: ¥50,000

【同意書】
├─ [同意書を作成] ボタン ← NEW
└─ 既存同意書:
   ├─ "アートメイク施術同意書" (2024-01-15 10:30) [PDF表示]
   └─ "麻酔同意書" (2024-01-15 10:35) [PDF表示]
```

---

### 画面5: 同意書作成画面（複数選択）

**パス**: `/medical_records/:medical_record_id/patient_consents/new`

**ステップ1: テンプレート選択**

```
同意書作成: カルテ#123 - 田中花子様

【使用する同意書テンプレートを選択】

[✓] アートメイク施術同意書
[✓] 麻酔同意書
[ ] その他の同意書

[次へ: 同意書を記入]
```

---

### 画面6: 同意書記入・署名画面

**パス**: `/medical_records/:medical_record_id/patient_consents/create`

```
同意書記入: アートメイク施術同意書

【説明文】
施術前に以下の内容をご確認ください。

【チェック項目】
☑ 施術にはリスクがあることを理解しました（必須）
☑ アレルギーの有無を正しく申告しました（必須）
☐ その他の注意事項を確認しました

【医師・施術者情報】
担当医師: [プルダウン選択] ← 施設「サロンA」の医師のみ
  ├─ 山田太郎医師（医123456）
  └─ 佐藤次郎医師（医789012）

施術者名: アートメイク施術者 田中（自動表示、編集不可）

【施設情報】（自動表示）
施設名: サロンA
住所: 東京都渋谷区...
電話番号: 03-1234-5678

━━━━━━━━━━━━━━━━━
|  患者署名エリア        |
|  Canvas手書き署名      |
|  [クリア] [確定]       |
━━━━━━━━━━━━━━━━━

[この同意書を保存]

---

【次の同意書: 麻酔同意書】（同様のフォーム）

---

[すべての同意書を保存して完了]
```

**Stimulus Controller**: `signature-controller.js`
**Gem追加**: `signature-pad-rails`

---

## 🛠️ 技術仕様

### 1. Canvas手書き署名実装

```javascript
// app/javascript/controllers/signature_controller.js
import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

export default class extends Controller {
  static targets = ["canvas", "dataField"]

  connect() {
    this.signaturePad = new SignaturePad(this.canvasTarget, {
      backgroundColor: 'rgb(255, 255, 255)',
      penColor: 'rgb(0, 0, 0)'
    })

    // Canvasサイズ調整
    this.resizeCanvas()
  }

  clear() {
    this.signaturePad.clear()
  }

  save() {
    if (this.signaturePad.isEmpty()) {
      alert("署名が必要です")
      return false
    }

    // Base64データをhidden fieldに保存
    const dataURL = this.signaturePad.toDataURL()
    this.dataFieldTarget.value = dataURL

    return true
  }

  resizeCanvas() {
    const canvas = this.canvasTarget
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    canvas.width = canvas.offsetWidth * ratio
    canvas.height = canvas.offsetHeight * ratio
    canvas.getContext("2d").scale(ratio, ratio)
    this.signaturePad.clear()
  }
}
```

### 2. PDF生成サービス

```ruby
# app/services/consent_form_pdf_generator.rb
class ConsentFormPdfGenerator
  def initialize(patient_consent)
    @consent = patient_consent
    @template = patient_consent.consent_form_template
    @patient = patient_consent.patient
    @medical_record = patient_consent.medical_record
    @doctor = patient_consent.facility_doctor
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 50) do |pdf|
      setup_font(pdf)

      render_header(pdf)
      render_description(pdf)
      render_checklist(pdf)
      render_staff_info(pdf)
      render_facility_info(pdf)
      render_signature(pdf)
      render_footer(pdf)
    end.render
  end

  private

  def setup_font(pdf)
    pdf.font_families.update('NotoSansJP' => {
      normal: Rails.root.join('app/assets/fonts/NotoSansJP-Regular.ttf')
    })
    pdf.font 'NotoSansJP'
  end

  def render_header(pdf)
    pdf.text @template.title, size: 18, style: :bold, align: :center
    pdf.move_down 20
  end

  def render_description(pdf)
    return unless @template.description.present?

    pdf.text @template.description, size: 10
    pdf.move_down 15
  end

  def render_checklist(pdf)
    @consent.consent_item_responses.includes(:consent_form_item).each do |response|
      checkbox = response.checked? ? "☑" : "☐"
      required = response.consent_form_item.is_required? ? "（必須）" : ""
      pdf.text "#{checkbox} #{response.consent_form_item.content}#{required}", size: 10
      pdf.move_down 5
    end

    pdf.move_down 20
  end

  def render_staff_info(pdf)
    pdf.text "【医師・施術者情報】", size: 12, style: :bold
    pdf.move_down 10
    pdf.text "担当医師: #{@doctor.name}", size: 10
    pdf.text "施術者: #{@consent.practitioner_name}", size: 10
    pdf.move_down 15
  end

  def render_facility_info(pdf)
    pdf.text "【施設情報】", size: 12, style: :bold
    pdf.move_down 10
    pdf.text "施設名: #{@consent.facility_name}", size: 10
    pdf.text "住所: #{@consent.facility_address}", size: 10 if @consent.facility_address.present?
    pdf.text "電話番号: #{@consent.facility_phone}", size: 10 if @consent.facility_phone.present?
    pdf.move_down 15
  end

  def render_signature(pdf)
    return unless @consent.signature_data.present?

    pdf.text "【患者署名】", size: 12, style: :bold
    pdf.move_down 10

    # Base64データをデコード
    image_data = Base64.decode64(@consent.signature_data.split(',')[1])
    pdf.image StringIO.new(image_data), width: 200, height: 60

    pdf.move_down 10
  end

  def render_footer(pdf)
    pdf.text "同意日: #{@consent.agreed_at.strftime('%Y年%m月%d日 %H:%M')}", size: 10
    pdf.move_down 5
    pdf.text "署名IP: #{@consent.signed_ip}", size: 8, color: '666666'

    # ページ番号
    pdf.number_pages "ページ <page> / <total>",
                     at: [pdf.bounds.right - 50, 0],
                     align: :right,
                     size: 8
  end
end
```

### 3. 暗号化設定

```ruby
# app/models/patient_consent.rb
class PatientConsent < ApplicationRecord
  # Active Record Encryption
  encrypts :signature_data
  encrypts :practitioner_name
  encrypts :facility_name
  encrypts :facility_address
  encrypts :facility_phone

  # 施設情報のスナップショット保存
  before_create :snapshot_facility_info
  before_create :record_request_info

  private

  def snapshot_facility_info
    facility = medical_record.facility
    self.facility_name = facility.name
    self.facility_address = facility.address
    self.facility_phone = facility.phone
    self.practitioner_name = user.company_name || user.email
  end

  def record_request_info
    # コントローラーから設定される想定
    # self.signed_ip = request.remote_ip
    # self.signed_user_agent = request.user_agent
  end
end
```

---

## 📅 実装スケジュール

### Phase 5-C-1: データモデル基盤（3-4日）

**ブランチ**: `feature/p5c1-consent-models`

**実装内容**:
1. マイグレーション作成（5ファイル）
2. モデル実装（5モデル）
   - FacilityDoctor
   - ConsentFormTemplate
   - ConsentFormItem
   - PatientConsent
   - ConsentItemResponse
3. Factory定義（5ファイル）
4. Model Spec（40-45件）

**テスト観点**:
- バリデーション（presence, uniqueness）
- アソシエーション
- 暗号化（PatientConsent）
- ネストフォーム（accepts_nested_attributes_for）
- 必須項目チェック（ConsentItemResponse）
- スナップショット保存（before_create callbacks）

**完了条件**:
- [ ] 全5マイグレーション実行成功
- [ ] 全5モデルのModel Spec成功
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし

---

### Phase 5-C-2: 施設医師・テンプレート管理UI（4-5日）

**ブランチ**: `feature/p5c2-consent-templates`

**実装内容**:
1. **施設編集画面の拡張**
   - Facilityフォームに医師情報を追加（ネストフォーム）
   - Stimulus Controller: `nested-form-controller.js`（医師の動的追加・削除）
   - ビュー: `_facility_doctor_fields.html.erb`

2. **同意書テンプレート管理**
   - ConsentFormTemplatesController (CRUD)
   - ビュー: index, new, edit, show
   - Stimulus Controller: `sortable-controller.js`（ドラッグ&ドロップ並び替え）
   - ネストフォーム: ConsentFormItem の動的追加・削除

3. **Gem追加**:
   ```ruby
   gem 'sortablejs-rails'
   ```

4. **Request/System Spec**:
   - Facilities + FacilityDoctor（15-20件）
   - ConsentFormTemplates CRUD（20-25件）
   - ドラッグ&ドロップ機能（System Spec）

**完了条件**:
- [ ] 施設編集画面で医師追加・削除可能
- [ ] 同意書テンプレートCRUD動作
- [ ] チェック項目の動的追加・削除動作
- [ ] ドラッグ&ドロップでposition更新成功
- [ ] Request Spec + System Spec成功

---

### Phase 5-C-3: 患者同意書・署名機能（4-5日）

**ブランチ**: `feature/p5c3-patient-consents`

**実装内容**:
1. **同意書作成画面**
   - PatientConsentsController (CRUD)
   - カルテ詳細画面に「同意書を作成」ボタン追加
   - 複数テンプレート選択UI
   - 施設に紐付く医師のプルダウン（Ajax動的読み込み）

2. **Canvas手書き署名**
   - Stimulus Controller: `signature-controller.js`
   - Base64データをhidden fieldに保存
   - 署名クリア・確定機能

3. **Gem追加**:
   ```ruby
   gem 'signature-pad-rails'
   ```

4. **Request/System Spec**:
   - PatientConsents CRUD（20-25件）
   - 署名機能テスト（Capybara + Cuprite + JavaScript）
   - 複数同意書の作成テスト

**完了条件**:
- [ ] カルテ詳細画面から同意書作成可能
- [ ] 複数テンプレート選択可能
- [ ] Canvas署名が正常動作
- [ ] Base64データがDB保存成功
- [ ] System Spec成功（JS実行含む）

---

### Phase 5-C-4: PDF生成機能（3-4日）

**ブランチ**: `feature/p5c4-consent-pdf`

**実装内容**:
1. **ConsentFormPdfGenerator サービス**
   - Prawnで日本語PDF生成
   - Noto Sans JPフォント使用
   - 署名画像埋め込み
   - 医師・施術者・施設情報表示
   - チェック項目表示（☑/☐）

2. **PDFプレビュー・ダウンロード**
   - PatientConsentsController#preview
   - PatientConsentsController#download
   - PDFファイル名: `同意書_患者名_日付.pdf`

3. **System Spec**:
   - PDF生成テスト（25-30件）
   - 複数同意書のPDF一括生成
   - PDF内容検証（PDF::Reader使用）

**完了条件**:
- [ ] PDF生成サービス実装完了
- [ ] 日本語フォント正常表示
- [ ] 署名画像が埋め込み成功
- [ ] PDFプレビュー・ダウンロード動作
- [ ] System Spec成功

---

## 📊 総合統計

| 項目 | 値 |
|------|-----|
| **総工数** | 14-18日（約3週間） |
| **サブフェーズ** | 4フェーズ（5-C-1 〜 5-C-4） |
| **新規モデル** | 5モデル |
| **新規コントローラー** | 2コントローラー |
| **マイグレーション** | 5ファイル |
| **追加テスト** | 110-125件 |
| **Gem追加** | `signature-pad-rails`, `sortablejs-rails` |
| **Stimulus Controllers** | 3ファイル（nested-form, sortable, signature） |

---

## 🔒 セキュリティ対策

### 1. 個人情報の暗号化

- Active Record Encryption で以下を暗号化:
  - `signature_data`（署名データ）
  - `practitioner_name`（施術者名）
  - `facility_name`, `facility_address`, `facility_phone`（施設情報）

### 2. 法的証跡の記録

- 署名時のIPアドレス記録
- 署名時のUser-Agent記録
- 同意日時（`agreed_at`）のタイムスタンプ

### 3. データの改ざん防止

- 施設情報のスナップショット保存（後から施設情報が変更されても同意書は保持）
- 同意書テンプレートのバージョン管理（将来的な拡張）

### 4. 権限制御

- ユーザーごとのデータスコープ分離
- `current_user` でのアクセス制御
- `before_action :authenticate_user!`

---

## 🧪 テスト戦略

### Model Spec（40-45件）

- バリデーションテスト
- アソシエーションテスト
- 暗号化テスト（復号化も確認）
- コールバックテスト（snapshot_facility_info）
- スコープテスト

### Request Spec（35-45件）

- CRUD操作テスト
- 認証・認可テスト
- パラメータバリデーションテスト
- エラーハンドリングテスト

### System Spec（30-35件）

- E2Eフローテスト
- JavaScript動作テスト（Cuprite使用）
- Canvas署名テスト
- ドラッグ&ドロップテスト
- PDF生成テスト

---

## 🎓 想定される技術的課題

### 課題1: Canvas署名のクロスブラウザ対応

**問題**: Safari, Chrome, Firefoxで挙動が異なる可能性

**対策**:
- Signature Pad ライブラリが主要ブラウザをサポート
- System Specで複数ブラウザテスト

---

### 課題2: 署名画像のPDF埋め込み

**問題**: Base64データのデコード・画像変換

**対策**:
- Prawnの`pdf.image StringIO.new(image_data)`で対応
- 既存のInvoice PDF実装パターンを参考

---

### 課題3: ネストフォームの複雑性

**問題**: ConsentFormTemplate + ConsentFormItem の二重ネスト

**対策**:
- `accepts_nested_attributes_for` + Stimulus で実装
- 既存のMedicalRecord + CostItem実装パターンを参考

---

### 課題4: 複数同意書の一括作成

**問題**: 1回の操作で複数の同意書を作成

**対策**:
- フォームで複数テンプレートを選択
- コントローラーでループ処理
- トランザクション制御（失敗時はロールバック）

---

## 🚀 デプロイ後の運用

### 1. 同意書テンプレートの管理

- 定期的にテンプレートを見直し
- 法律変更に応じた項目追加・削除

### 2. PDF保管

- Active Storageによる保管
- Cloudflare R2でのバックアップ

### 3. 監査ログ

- 同意書作成・削除のログ記録
- 法的紛争時の証跡として活用

---

## 📝 次のアクション

### Phase 5-C完了後

1. **Phase 5-D以降の再計画**
   - パフォーマンス最適化（旧Phase 5-C）
   - 本番デプロイ（旧Phase 5-D）
   - 追加機能検討

2. **ギャップ分析更新**
   - `docs/gap_analysis.md` を更新
   - Phase 5-C完了報告作成

---

**作成者**: Claude Code + User
**最終更新**: 2025-10-17
