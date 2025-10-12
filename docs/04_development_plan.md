# 開発フェーズとマイルストーン計画

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0

---

## 1. 開発方針

### 1.1 開発アプローチ

- **TDD（Test-Driven Development）**: テストファーストで実装
- **アジャイル開発**: 1-2週間のイテレーションで段階的に機能追加
- **MVP重視**: まず最小限の機能で動くものを作り、段階的に拡張
- **継続的フィードバック**: 実際のユーザー（施術者）からのフィードバックを重視

### 1.2 品質基準

| 指標 | 目標値 |
|------|--------|
| テストカバレッジ | 80%以上 |
| RuboCop違反 | 0件 |
| Brakeman警告 | 0件（Critical/High） |
| ページ表示速度 | 2秒以内 |
| レスポンシブ対応 | PC/タブレット/スマホ |

---

## 2. 開発フェーズ全体像

### 2.1 タイムライン概要

```
Week 1-2:  Phase 0 - 環境構築・基盤整備
Week 3-6:  Phase 1 - MVP開発（コア機能）
Week 7-9:  Phase 2 - 拡張機能（売上・請求書）
Week 10:   Phase 3 - 改善・最適化
Week 11:   Phase 4 - デプロイ・運用開始
```

**総期間**: 約11週間（2.5ヶ月）

---

## 3. Phase 0: 環境構築・基盤整備（Week 1-2）

### 3.1 目標

- 開発環境のセットアップ完了
- 基本的なプロジェクト構造の確立
- CI/CD パイプラインの構築

### 3.2 タスク詳細

#### Week 1: 環境構築

| タスク | 内容 | 時間 | 優先度 |
|--------|------|------|--------|
| **開発環境セットアップ** | Ruby, Rails, PostgreSQL, Node.js インストール | 2h | 🔴 |
| **Railsプロジェクト作成** | `rails new` + 初期設定 | 1h | 🔴 |
| **Git リポジトリ初期化** | GitHub リポジトリ作成・初期コミット | 1h | 🔴 |
| **RSpec セットアップ** | RSpec, FactoryBot, SimpleCov 導入 | 2h | 🔴 |
| **RuboCop セットアップ** | RuboCop, rubocop-rails 導入・設定 | 1h | 🟡 |
| **Devise セットアップ** | Devise + OmniAuth 導入 | 3h | 🔴 |
| **Tailwind CSS カスタマイズ** | 基本コンポーネントスタイル定義 | 2h | 🟡 |

**Week 1 成果物:**
- ✅ 開発環境が整い、`rails s` でサーバー起動可能
- ✅ GitHubリポジトリにプッシュ完了
- ✅ RSpec, RuboCop が実行可能
- ✅ Devise によるログイン画面表示

---

#### Week 2: 基盤機能開発

| タスク | 内容 | 時間 | 優先度 |
|--------|------|------|--------|
| **User認証機能** | Devise ログイン・ログアウト | 2h | 🔴 |
| **Google OAuth連携** | OmniAuth Google ログイン | 3h | 🔴 |
| **レイアウト作成** | ヘッダー、フッター、ナビゲーション | 3h | 🔴 |
| **ダッシュボード画面** | ホーム画面（仮） | 2h | 🟡 |
| **Active Storage設定** | 画像アップロード基盤 | 2h | 🔴 |
| **初期テスト作成** | User モデルのテスト | 2h | 🔴 |

**Week 2 成果物:**
- ✅ メール/パスワードでログイン可能
- ✅ Googleアカウントでログイン可能
- ✅ 共通レイアウトが整っている
- ✅ テストが通る（User認証）

**Milestone 0 達成条件:**
- [ ] 開発環境セットアップ完了
- [ ] ユーザー認証機能完成
- [ ] 基本レイアウト完成
- [ ] テスト実行可能（カバレッジ計測）

---

## 4. Phase 1: MVP開発（Week 3-6）

### 4.1 目標

- カルテの作成・閲覧・編集ができる
- 患者・施術場所・コストシートの管理ができる
- 検索・フィルタリングができる

### 4.2 Week 3: 施術場所・患者管理

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **Facility モデル作成** | 1. モデルテスト → 2. マイグレーション → 3. バリデーション | 2h | 🔴 |
| **Facility CRUD** | 1. Request spec → 2. Controller実装 → 3. View作成 | 4h | 🔴 |
| **Patient モデル作成** | 同上 | 2h | 🔴 |
| **Patient CRUD** | 同上 | 4h | 🔴 |
| **関連テスト** | User has_many Facilities/Patients | 1h | 🔴 |
| **UI調整** | フォームデザイン、一覧表示 | 2h | 🟡 |

#### TDD実装例（Facility）

```ruby
# 1. Red: テスト作成
# spec/models/facility_spec.rb
RSpec.describe Facility, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end
end

# 2. Green: 実装
# app/models/facility.rb
class Facility < ApplicationRecord
  belongs_to :user
  validates :name, presence: true, length: { maximum: 100 }
end

# 3. Refactor: 必要に応じてリファクタリング
```

**Week 3 成果物:**
- ✅ 施術場所の登録・編集・削除・一覧表示
- ✅ 患者の登録・編集・削除・一覧表示
- ✅ モデル・コントローラーのテスト完成

---

### 4.3 Week 4: コストシート管理

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **CostSheet モデル作成** | 1. モデルテスト → 2. マイグレーション → 3. バリデーション | 2h | 🔴 |
| **CostSheet CRUD** | 1. Request spec → 2. Controller実装 → 3. View作成 | 4h | 🔴 |
| **カテゴリ機能** | enum or Tag機能 | 2h | 🟡 |
| **テンプレート選択UI** | JavaScript（Stimulus）で動的選択 | 3h | 🔴 |
| **シードデータ作成** | サンプルコストシート | 1h | 🟡 |
| **UI調整** | カード表示、検索機能 | 2h | 🟡 |

**Week 4 成果物:**
- ✅ コストシートの登録・編集・削除・一覧表示
- ✅ カテゴリによる分類
- ✅ テンプレート選択UIの基本動作

---

### 4.4 Week 5: カルテ管理（基本）

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **MedicalRecord モデル作成** | 1. モデルテスト → 2. マイグレーション | 2h | 🔴 |
| **CostItem モデル作成** | 同上（nested attributes対応） | 2h | 🔴 |
| **カルテ作成画面** | フォーム作成（患者・施術場所選択） | 4h | 🔴 |
| **コスト項目追加機能** | JavaScript動的フォーム | 4h | 🔴 |
| **金額自動計算** | Stimulus コントローラー | 2h | 🔴 |
| **画像アップロード** | Active Storage 統合 | 2h | 🔴 |
| **カルテ一覧画面** | 基本的な一覧表示 | 2h | 🔴 |

#### 技術的ポイント

**nested_attributes によるコスト項目管理:**

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  has_many :cost_items, dependent: :destroy
  accepts_nested_attributes_for :cost_items, allow_destroy: true

  after_save :update_total_amount

  private

  def update_total_amount
    update_column(:total_amount, cost_items.sum(:subtotal))
  end
end
```

**Stimulusによる動的フォーム:**

```javascript
// app/javascript/controllers/cost_items_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "total"]

  addItem(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest('.cost-item')
    item.querySelector('input[name*="_destroy"]').value = 1
    item.style.display = 'none'
    this.calculateTotal()
  }

  calculateTotal() {
    let total = 0
    this.containerTarget.querySelectorAll('.cost-item:not([style*="display: none"])').forEach(item => {
      const price = parseFloat(item.querySelector('.unit-price').value) || 0
      const qty = parseInt(item.querySelector('.quantity').value) || 1
      total += price * qty
    })
    this.totalTarget.textContent = total.toLocaleString()
  }
}
```

**Week 5 成果物:**
- ✅ カルテ作成・編集機能
- ✅ コスト項目の動的追加・削除
- ✅ 画像アップロード機能
- ✅ 合計金額の自動計算

---

### 4.5 Week 6: 検索・詳細機能

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **Tag モデル作成** | 1. モデルテスト → 2. マイグレーション | 2h | 🔴 |
| **カルテ検索機能** | Ransack or 自作検索 | 4h | 🔴 |
| **フィルタリングUI** | 施術場所、日付、タグで絞り込み | 3h | 🔴 |
| **カルテ詳細画面** | 詳細情報表示 | 2h | 🔴 |
| **ページネーション** | Kaminari 導入 | 2h | 🟡 |
| **統合テスト** | Capybara でE2Eテスト | 3h | 🔴 |
| **UI/UX改善** | レスポンシブ対応、エラーメッセージ | 2h | 🟡 |

**Week 6 成果物:**
- ✅ カルテの検索・フィルタリング機能
- ✅ タグによる分類
- ✅ カルテ詳細画面
- ✅ E2Eテスト完成

**Milestone 1 達成条件（MVP完成）:**
- [ ] 施術場所・患者・コストシート・カルテの CRUD完成
- [ ] カルテ作成時にコスト項目を選択・追加可能
- [ ] 画像アップロード機能動作
- [ ] 検索・フィルタリング機能動作
- [ ] テストカバレッジ 80%以上
- [ ] RuboCop違反 0件

---

## 5. Phase 2: 拡張機能（Week 7-9）

### 5.1 目標

- 売上管理ダッシュボード
- 請求書自動生成・PDF出力
- 月次総合売上表

### 5.2 Week 7: 売上管理ダッシュボード

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **売上集計ロジック** | Model層で集計メソッド作成 | 3h | 🔴 |
| **ダッシュボード画面** | 月次・年次売上表示 | 3h | 🔴 |
| **施術場所別売上** | グループ化・集計 | 2h | 🔴 |
| **グラフ表示** | Chart.js or Chartkick | 3h | 🟡 |
| **期間指定機能** | カスタム期間での集計 | 2h | 🟡 |
| **CSV エクスポート** | 売上データCSV出力 | 2h | 🟡 |

#### 売上集計例

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  scope :in_period, ->(start_date, end_date) { where(treatment_date: start_date..end_date) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }

  def self.total_revenue(start_date, end_date)
    in_period(start_date, end_date).sum(:total_amount)
  end

  def self.revenue_by_facility(start_date, end_date)
    in_period(start_date, end_date)
      .joins(:facility)
      .group('facilities.name')
      .sum(:total_amount)
  end

  def self.monthly_revenue(year)
    (1..12).map do |month|
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      {
        month: month,
        revenue: total_revenue(start_date, end_date)
      }
    end
  end
end
```

**Week 7 成果物:**
- ✅ 売上ダッシュボード画面
- ✅ 月次・年次売上集計
- ✅ 施術場所別売上表示
- ✅ グラフ表示（オプション）
- ✅ CSV エクスポート

---

### 5.3 Week 8: 請求書生成機能

#### タスク一覧

| タスク | TDD手順 | 時間 | 優先度 |
|--------|---------|------|--------|
| **Invoice モデル作成** | 1. モデルテスト → 2. マイグレーション | 2h | 🔴 |
| **請求書自動生成ロジック** | 施術場所×月で集計 | 3h | 🔴 |
| **請求書一覧画面** | 発行済み請求書の管理 | 2h | 🔴 |
| **請求書プレビュー** | HTML で表示 | 2h | 🔴 |
| **PDF生成機能（Prawn）** | PDF出力 | 4h | 🔴 |
| **日本語フォント対応** | IPA フォント設定 | 2h | 🔴 |
| **請求書番号自動採番** | INV-YYYYMM-XXXX 形式 | 1h | 🔴 |

#### Prawn PDF生成例

```ruby
# app/services/invoice_pdf_generator.rb
class InvoicePdfGenerator
  def initialize(invoice)
    @invoice = invoice
    @pdf = Prawn::Document.new
  end

  def generate
    setup_fonts
    render_header
    render_billing_info
    render_table
    render_footer
    @pdf.render
  end

  private

  def setup_fonts
    font_path = Rails.root.join('app', 'assets', 'fonts', 'ipaexg.ttf')
    @pdf.font_families.update('IPAexGothic' => { normal: font_path })
    @pdf.font 'IPAexGothic'
  end

  def render_header
    @pdf.text '請求書', size: 24, align: :center, style: :bold
    @pdf.move_down 10
    @pdf.text "請求書番号: #{@invoice.invoice_number}", size: 12
    @pdf.text "発行日: #{@invoice.issue_date}", size: 12
    @pdf.move_down 20
  end

  def render_billing_info
    @pdf.text "宛先: #{@invoice.facility.name}", size: 14
    @pdf.text "期間: #{@invoice.billing_period_start} 〜 #{@invoice.billing_period_end}"
    @pdf.move_down 20
  end

  def render_table
    table_data = [['日付', '患者名', '施術内容', '金額']]

    @invoice.medical_records.each do |record|
      table_data << [
        record.treatment_date.to_s,
        record.patient.name,
        record.treatment_content.truncate(30),
        "¥#{record.total_amount.to_i.to_s(:delimited)}"
      ]
    end

    table_data << ['', '', '合計', "¥#{@invoice.total_amount.to_i.to_s(:delimited)}"]

    @pdf.table(table_data, header: true, width: @pdf.bounds.width) do
      row(0).font_style = :bold
      row(-1).font_style = :bold
      columns(3).align = :right
    end
  end

  def render_footer
    @pdf.move_down 30
    @pdf.text '振込先: 〇〇銀行 △△支店 普通 1234567', size: 10
    @pdf.text 'お振込期限: #{(@invoice.issue_date + 30.days).to_s}', size: 10
  end
end
```

**Week 8 成果物:**
- ✅ 請求書自動生成機能
- ✅ 請求書一覧・詳細画面
- ✅ PDF 出力機能
- ✅ 日本語フォント対応

---

### 5.4 Week 9: 統合・テスト・改善

#### タスク一覧

| タスク | 内容 | 時間 | 優先度 |
|--------|------|------|--------|
| **月次総合売上表** | 確定申告用の集計表 | 2h | 🔴 |
| **統合テスト追加** | Phase 2機能のE2Eテスト | 4h | 🔴 |
| **バグ修正** | テスト中に発見した問題修正 | 4h | 🔴 |
| **パフォーマンス最適化** | N+1クエリ解消、インデックス追加 | 3h | 🟡 |
| **UI/UX改善** | ユーザビリティ向上 | 3h | 🟡 |
| **ドキュメント更新** | README, 使い方ガイド | 2h | 🟡 |

**Week 9 成果物:**
- ✅ 月次総合売上表
- ✅ Phase 2機能のテスト完成
- ✅ パフォーマンス最適化
- ✅ ドキュメント整備

**Milestone 2 達成条件（Phase 2完成）:**
- [ ] 売上管理ダッシュボード完成
- [ ] 請求書自動生成・PDF出力完成
- [ ] 月次総合売上表完成
- [ ] テストカバレッジ維持（80%以上）
- [ ] パフォーマンス目標達成（2秒以内）

---

## 6. Phase 3: 改善・最適化（Week 10）

### 6.1 目標

- UI/UX の最終調整
- パフォーマンスチューニング
- セキュリティ強化
- アクセシビリティ改善

### 6.2 タスク一覧

| タスク | 内容 | 時間 | 優先度 |
|--------|------|------|--------|
| **レスポンシブ対応確認** | モバイル・タブレットでの表示確認 | 3h | 🔴 |
| **アクセシビリティ改善** | ARIA属性、キーボード操作 | 2h | 🟡 |
| **セキュリティ監査** | Brakeman実行、脆弱性対応 | 2h | 🔴 |
| **パフォーマンス測定** | Lighthouse, Bullet実行 | 2h | 🟡 |
| **データベース最適化** | インデックス追加、クエリ改善 | 2h | 🟡 |
| **エラーハンドリング強化** | 404, 500エラーページ | 2h | 🟡 |
| **ログ・監視設定** | ログレベル調整、Sentry導入検討 | 2h | 🟡 |
| **最終テスト** | 全機能の総合テスト | 3h | 🔴 |

**Week 10 成果物:**
- ✅ レスポンシブデザイン完成
- ✅ セキュリティ対策完了
- ✅ パフォーマンス最適化完了
- ✅ エラーハンドリング強化

**Milestone 3 達成条件（改善完了）:**
- [ ] Lighthouse スコア 90点以上（Performance）
- [ ] Brakeman 警告 0件（Critical/High）
- [ ] 全デバイスでの動作確認完了
- [ ] 最終テスト完了

---

## 7. Phase 4: デプロイ・運用開始（Week 11）

### 7.1 目標

- 本番環境へのデプロイ
- 初期データ投入
- ユーザー（施術者）への引き渡し
- 運用開始

### 7.2 タスク一覧

| タスク | 内容 | 時間 | 優先度 |
|--------|------|------|--------|
| **Render アカウント作成** | Renderアカウント準備 | 0.5h | 🔴 |
| **PostgreSQL DB作成** | Render上でDB作成 | 0.5h | 🔴 |
| **環境変数設定** | RAILS_MASTER_KEY, AWS設定など | 1h | 🔴 |
| **AWS S3 設定** | バケット作成、権限設定 | 1h | 🔴 |
| **デプロイ実行** | Renderへプッシュ | 1h | 🔴 |
| **マイグレーション実行** | 本番DBマイグレーション | 0.5h | 🔴 |
| **初期データ投入** | 施術者アカウント、基本データ | 1h | 🔴 |
| **動作確認** | 本番環境での全機能確認 | 3h | 🔴 |
| **ドキュメント作成** | ユーザーマニュアル作成 | 3h | 🟡 |
| **ユーザー説明・引き渡し** | 施術者への操作説明 | 2h | 🔴 |
| **運用監視設定** | エラー通知、バックアップ確認 | 2h | 🟡 |

### 7.3 デプロイチェックリスト

**本番環境確認項目:**

- [ ] ログイン・ログアウト動作
- [ ] 施術場所・患者・コストシート・カルテ CRUD
- [ ] 画像アップロード（S3）
- [ ] 検索・フィルタリング
- [ ] 売上ダッシュボード
- [ ] 請求書生成・PDF出力
- [ ] CSV エクスポート
- [ ] レスポンシブ表示
- [ ] エラーページ表示
- [ ] HTTPS 接続
- [ ] データベースバックアップ

**Week 11 成果物:**
- ✅ 本番環境デプロイ完了
- ✅ 初期データ投入完了
- ✅ ユーザーマニュアル作成
- ✅ 運用開始

**Milestone 4 達成条件（プロジェクト完了）:**
- [ ] 本番環境で全機能動作
- [ ] 実際のユーザーが使用開始
- [ ] ドキュメント完備
- [ ] GitHubリポジトリ公開
- [ ] ポートフォリオとして提出可能

---

## 8. 継続的改善（運用開始後）

### 8.1 フィードバックループ

運用開始後は以下のサイクルで改善を続ける:

```
1週間ごと: ユーザーフィードバック収集
2週間ごと: 優先度の高い改善実施
1ヶ月ごと: 新機能検討・計画
```

### 8.2 Phase 3 候補機能

| 機能 | 優先度 | 実装時期 |
|------|--------|---------|
| カスタムタグ機能拡張 | 🟡 | 1ヶ月後 |
| データエクスポート（全データ） | 🟡 | 1ヶ月後 |
| レポート機能（統計） | 🟢 | 2ヶ月後 |
| モバイルアプリ（React Native） | 🟢 | 3ヶ月後〜 |
| 複数施術者対応 | 🟢 | 将来的に |

---

## 9. リスク管理

### 9.1 想定リスクと対策

| リスク | 発生確率 | 影響度 | 対策 |
|--------|---------|--------|------|
| スケジュール遅延 | 高 | 中 | MVP重視、Phase 3は後回し可 |
| 技術的困難（PDF生成） | 中 | 中 | 早期プロトタイプで検証 |
| ユーザー要件変更 | 中 | 中 | アジャイル開発で柔軟対応 |
| セキュリティ脆弱性 | 低 | 高 | Brakeman定期実行、Rails標準機能活用 |
| API制限超過 | 低 | 低 | 無料枠内で設計 |
| デプロイ失敗 | 中 | 中 | ステージング環境で事前確認 |

### 9.2 スケジュール遅延時の対応

**優先順位による機能削減:**

1. **削減不可（MVP）:**
   - 認証機能
   - カルテ CRUD
   - コスト選択機能
   - 基本的な検索

2. **削減可能（Phase 2）:**
   - グラフ表示
   - CSV エクスポート
   - 月次総合売上表

3. **削減推奨（Phase 3）:**
   - カスタムタグ拡張
   - レポート機能
   - UI/UXの細かい調整

---

## 10. 成功基準の最終確認

### 10.1 学習目標

- [ ] Ruby/Rails の CRUD操作を習得
- [ ] TDDによる開発プロセスを実践
- [ ] 認証システムの実装経験
- [ ] 外部API連携（OAuth, S3）
- [ ] デプロイ経験
- [ ] テストカバレッジ 80%以上達成

### 10.2 実用性

- [ ] 実際の施術者が使用可能
- [ ] コスト入力時間が削減（目標: 50%削減）
- [ ] 請求書作成が自動化
- [ ] 売上がリアルタイムで把握可能
- [ ] セキュリティ要件を満たす

### 10.3 ポートフォリオ

- [ ] 問題発見から解決までのプロセスが明確
- [ ] GitHubでコード公開
- [ ] README、技術ドキュメント整備
- [ ] デモ動画作成（オプション）
- [ ] 本番環境での稼働実績

---

## 11. 週次チェックポイント

各週の終わりに以下を確認:

### チェック項目

- [ ] 今週の目標タスク完了率（80%以上が理想）
- [ ] テスト実行・合格（RSpec）
- [ ] RuboCop違反なし
- [ ] GitHubへのコミット・プッシュ
- [ ] ドキュメント更新
- [ ] 次週のタスク明確化

### 週次レビュー項目

1. **今週できたこと**: 完了したタスク列挙
2. **今週できなかったこと**: 未完了タスクと理由
3. **学んだこと**: 技術的な学び、課題
4. **次週の目標**: 重点タスク3つ
5. **リスク・懸念**: 早期に対処すべき問題

---

## 12. 開発環境・ツール

### 12.1 日常的に使うコマンド

```bash
# サーバー起動
rails s

# テスト実行
bundle exec rspec

# コード品質チェック
bundle exec rubocop -A

# マイグレーション
rails db:migrate

# コンソール
rails c

# ルート確認
rails routes | grep medical_records
```

### 12.2 便利なエイリアス設定

`.zshrc` or `.bash_profile` に追加:

```bash
alias rs='rails s'
alias rc='rails c'
alias rdbm='rails db:migrate'
alias rspec='bundle exec rspec'
alias rubocop='bundle exec rubocop -A'
alias be='bundle exec'
```

---

## 13. ドキュメント管理

### 13.1 作成・更新するドキュメント

| ドキュメント | タイミング | 場所 |
|-------------|----------|------|
| **要件定義書** | Phase 0完了時 | `docs/01_requirements.md` |
| **データモデル設計** | Phase 0完了時 | `docs/02_data_model.md` |
| **技術選定** | Phase 0完了時 | `docs/03_technical_stack.md` |
| **開発計画** | Phase 0完了時 | `docs/04_development_plan.md` |
| **README** | 継続的に更新 | `README.md` |
| **API仕様書** | Phase 1完了時 | `docs/api_specification.md` |
| **ユーザーマニュアル** | Phase 4 | `docs/user_manual.md` |
| **デプロイ手順** | Phase 4 | `docs/deployment.md` |

### 13.2 README 推奨内容

```markdown
# 電子カルテアプリ

フリーランス美容施術者向けの電子カルテ管理システム

## 概要
- 目的・背景
- 主な機能
- デモURL（あれば）

## 技術スタック
- Ruby 3.2.2
- Rails 7.1.x
- PostgreSQL 14+
- Hotwire (Turbo + Stimulus)
- Tailwind CSS

## セットアップ
1. リポジトリクローン
2. bundle install
3. rails db:create db:migrate
4. rails s

## テスト
bundle exec rspec

## デプロイ
Render へのデプロイ手順

## ライセンス
MIT License

## 作者
Your Name
```

---

## 付録: 参考スケジュール（ガントチャート風）

```
Week 1: [環境構築] [Devise]
Week 2: [OAuth] [レイアウト] [ActiveStorage]
Week 3: [Facility] [Patient]
Week 4: [CostSheet] [UI]
Week 5: [MedicalRecord] [CostItem] [画像]
Week 6: [検索] [Tag] [E2E]
Week 7: [売上管理] [グラフ]
Week 8: [Invoice] [PDF]
Week 9: [統合] [最適化]
Week 10: [改善] [セキュリティ]
Week 11: [デプロイ] [運用開始]
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: Phase 1完了時

**注意**: このスケジュールは目安です。実際の進捗に応じて柔軟に調整してください。
