# 招待コードシステム実装計画

**作成日**: 2025-10-27
**目的**: クローズドβ運用のための招待コード必須化システムの実装
**開発方針**: TDD、段階的実装（3フェーズ）

---

## 📋 全体概要

### 実装目的

- クローズドβ運用期間中、新規登録を招待コード保持者に限定
- 管理者が招待コードを発行・管理できる仕組みの提供
- 使用回数・有効期限の制御による柔軟な運用

### 実装スコープ

1. **InvitationCodeモデル**: 招待コードのデータ構造とロジック
2. **会員登録フロー変更**: 招待コード必須化
3. **管理者機能**: 招待コード発行・管理・CSV出力

### 非スコープ（将来実装）

- 招待コード経由で登録したユーザーの追跡・分析
- 招待コード使用履歴の詳細ログ
- 招待コードのグループ管理（キャンペーン別等）

---

## 🏗️ アーキテクチャ設計

### データモデル

```ruby
# InvitationCode
class InvitationCode < ApplicationRecord
  # カラム:
  # - code: string (unique, not null) - 招待コード本体
  # - max_uses: integer (nullable) - 最大使用回数（nilの場合は無制限）
  # - used_count: integer (default: 0, not null) - 使用回数
  # - expires_at: datetime (nullable) - 有効期限
  # - created_by_id: integer (not null) - 作成した管理者のID
  # - status: integer (default: 0, not null) - ステータス（enum: active/inactive）
  # - memo: text (nullable) - メモ（管理者用）
  # - created_at, updated_at

  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  has_many :users

  enum :status, { active: 0, inactive: 1 }, default: :active

  validates :code, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[A-Z0-9]{6,12}\z/,
                            message: 'は6〜12文字の英数字（大文字）で入力してください' }
  validates :max_uses, numericality: { greater_than: 0, allow_nil: true }
  validates :used_count, numericality: { greater_than_or_equal_to: 0 }
  validates :created_by, presence: true

  # スコープ
  scope :active, -> { where(status: :active) }
  scope :available, -> {
    active.where('expires_at IS NULL OR expires_at > ?', Time.current)
  }

  # インスタンスメソッド
  def available?
    active? && !expired? && !max_uses_reached?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def max_uses_reached?
    max_uses.present? && used_count >= max_uses
  end

  def increment_used_count!
    increment!(:used_count)
  end

  def remaining_uses
    return Float::INFINITY if max_uses.nil?
    [max_uses - used_count, 0].max
  end

  # クラスメソッド
  def self.generate_code(length: 8)
    loop do
      code = SecureRandom.alphanumeric(length).upcase
      break code unless exists?(code: code)
    end
  end
end

# User モデルへの追加
class User < ApplicationRecord
  belongs_to :invitation_code, optional: true

  # 仮想属性（フォーム用）
  attr_accessor :invitation_code_text

  # バリデーション
  validates :invitation_code_text, presence: { message: '招待コードを入力してください' }, on: :create
  validate :validate_invitation_code, on: :create

  private

  def validate_invitation_code
    return if invitation_code_text.blank?

    code = InvitationCode.find_by(code: invitation_code_text.upcase)

    unless code&.available?
      errors.add(:invitation_code_text, 'は無効です')
      return
    end

    self.invitation_code = code
  end
end
```

### マイグレーション

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_invitation_codes.rb
class CreateInvitationCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :invitation_codes do |t|
      t.string :code, null: false
      t.integer :max_uses
      t.integer :used_count, default: 0, null: false
      t.datetime :expires_at
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.text :memo

      t.timestamps
    end

    add_index :invitation_codes, :code, unique: true
    add_index :invitation_codes, :status
    add_index :invitation_codes, :expires_at
  end
end

# db/migrate/YYYYMMDDHHMMSS_add_invitation_code_to_users.rb
class AddInvitationCodeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :invitation_code, foreign_key: true, index: true
  end
end
```

---

## 📦 段階的実装計画

### Phase 1: InvitationCodeモデル基盤実装 (1.5-2日)

**ブランチ**: `feature/invitation-code-model`

**実装内容**:
1. InvitationCodeモデル作成
2. マイグレーション実行
3. バリデーション実装
4. ビジネスロジック実装
   - `available?`, `expired?`, `max_uses_reached?`
   - `increment_used_count!`, `remaining_uses`
   - `self.generate_code`
5. Model Spec（100%カバレッジ）

**テストケース**:
- バリデーション: code必須、一意性、フォーマット
- バリデーション: max_uses正数、used_count非負
- ステータス: active/inactive
- 使用可能判定: available?の各条件
- 有効期限判定: expired?
- 使用回数上限判定: max_uses_reached?
- 使用回数インクリメント: increment_used_count!
- 残り使用回数計算: remaining_uses
- コード自動生成: generate_code（重複なし）

**成果物**:
- `app/models/invitation_code.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_invitation_codes.rb`
- `spec/models/invitation_code_spec.rb`
- `spec/factories/invitation_codes.rb`

**完了条件**:
- [ ] Model Spec全てパス
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] カバレッジ100%

---

### Phase 2: 会員登録フロー統合 (2-2.5日)

**ブランチ**: `feature/invitation-code-registration`

**前提**: Phase 1がマージ済み

**実装内容**:
1. Userモデルへのinvitation_code関連付け
2. マイグレーション（add_invitation_code_to_users）
3. Users::RegistrationsController変更
   - `validate_invitation_code` before_action
   - `sign_up_params`への招待コード追加
   - 登録成功時の使用回数インクリメント
4. 新規登録画面への招待コード入力欄追加
5. エラーメッセージ表示
6. Model/Request/System Spec

**テストケース**:
- User: invitation_code_text必須バリデーション
- User: 有効な招待コードでの登録成功
- User: 無効な招待コードでの登録失敗
- Request: 招待コード未入力時のエラー
- Request: 期限切れコードでの登録失敗
- Request: 使用回数上限到達コードでの登録失敗
- Request: inactiveコードでの登録失敗
- Request: 登録成功時の使用回数インクリメント
- System: 招待コード入力フォームの表示
- System: 有効コードでの登録フロー完走
- System: 無効コードでのエラー表示

**成果物**:
- `app/models/user.rb` (invitation_code関連追加)
- `app/controllers/users/registrations_controller.rb` (変更)
- `app/views/devise/registrations/new.html.erb` (変更)
- `db/migrate/YYYYMMDDHHMMSS_add_invitation_code_to_users.rb`
- `spec/models/user_spec.rb` (招待コードテスト追加)
- `spec/requests/users/registrations_spec.rb`
- `spec/system/authentication_flow_spec.rb` (招待コードテスト追加)

**完了条件**:
- [ ] 全Spec通過
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] 招待コードなしでは登録不可を確認

---

### Phase 3: 管理者機能実装 (2.5-3日)

**ブランチ**: `feature/invitation-code-admin`

**前提**: Phase 1, 2がマージ済み

**実装内容**:
1. Admin::InvitationCodesController作成
   - index: 一覧表示（検索・ソート・ページネーション）
   - new/create: 発行（自動生成/カスタム）
   - update: ステータス変更（active ⇄ inactive）
   - export: CSV出力
2. ビュー作成
   - 一覧画面（使用状況、有効期限、ステータス表示）
   - 発行フォーム（コード、使用回数制限、有効期限、メモ）
3. ルーティング設定
4. ナビゲーションへのリンク追加
5. Pundit認可（adminロールのみ）
6. Request/System Spec

**テストケース**:
- Request: adminユーザーのみアクセス可能
- Request: 一覧表示（アクティブ/期限切れ/使用回数上限）
- Request: 招待コード発行（自動生成）
- Request: 招待コード発行（カスタム、重複エラー）
- Request: ステータス変更（active → inactive → active）
- Request: CSV出力（全カラム含む）
- System: 招待コード一覧画面の表示
- System: 招待コード発行フロー
- System: ステータス変更操作
- System: CSV出力操作

**成果物**:
- `app/controllers/admin/invitation_codes_controller.rb`
- `app/views/admin/invitation_codes/index.html.erb`
- `app/views/admin/invitation_codes/new.html.erb`
- `app/policies/invitation_code_policy.rb`
- `config/routes.rb` (admin namespace追加)
- `spec/requests/admin/invitation_codes_spec.rb`
- `spec/system/admin/invitation_codes_spec.rb`

**完了条件**:
- [ ] 全Spec通過
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] CSV出力動作確認

---

## 🧪 テスト戦略

### Model Spec

```ruby
# spec/models/invitation_code_spec.rb
RSpec.describe InvitationCode, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).case_insensitive }
    it { should validate_numericality_of(:max_uses).is_greater_than(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many(:users) }
  end

  describe '#available?' do
    context 'when all conditions are met' do
      it 'returns true'
    end

    context 'when status is inactive' do
      it 'returns false'
    end

    context 'when expired' do
      it 'returns false'
    end

    context 'when max uses reached' do
      it 'returns false'
    end
  end

  describe '.generate_code' do
    it 'generates unique 8-character code by default'
    it 'generates code with specified length'
    it 'does not generate duplicate codes'
  end
end
```

### Request Spec

```ruby
# spec/requests/users/registrations_spec.rb
RSpec.describe 'Users::Registrations', type: :request do
  describe 'POST /users' do
    context 'with valid invitation code' do
      it 'creates user and increments code used_count'
    end

    context 'without invitation code' do
      it 'returns error'
    end

    context 'with expired invitation code' do
      it 'returns error'
    end

    context 'with max uses reached code' do
      it 'returns error'
    end
  end
end
```

### System Spec

```ruby
# spec/system/admin/invitation_codes_spec.rb
RSpec.describe 'Admin Invitation Codes Management', type: :system do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe '招待コード発行', js: true do
    it '管理者が招待コードを発行できる'
    it '自動生成ボタンでコードが生成される'
    it 'カスタムコードで発行できる'
  end

  describe '招待コード一覧', js: true do
    it '招待コード一覧が表示される'
    it 'ステータスで絞り込みができる'
    it '使用状況が表示される'
  end
end
```

---

## 🎨 UI/UX設計

### 新規登録画面（Phase 2）

```
┌─────────────────────────────────────┐
│   新規アカウント登録                │
├─────────────────────────────────────┤
│                                     │
│  招待コード *                       │
│  ┌───────────────────────────────┐ │
│  │ ABCD1234                      │ │
│  └───────────────────────────────┘ │
│  ※ 招待コードをお持ちでない方は、  │
│     管理者にお問い合わせください    │
│                                     │
│  メールアドレス *                   │
│  ┌───────────────────────────────┐ │
│  │ user@example.com              │ │
│  └───────────────────────────────┘ │
│                                     │
│  パスワード *                       │
│  ┌───────────────────────────────┐ │
│  │ ••••••••                      │ │
│  └───────────────────────────────┘ │
│                                     │
│  パスワード（確認） *               │
│  ┌───────────────────────────────┐ │
│  │ ••••••••                      │ │
│  └───────────────────────────────┘ │
│                                     │
│  □ 利用規約に同意する              │
│  □ プライバシーポリシーに同意する  │
│                                     │
│  ┌───────────────────────────────┐ │
│  │     新規登録                   │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 管理者：招待コード一覧（Phase 3）

```
┌─────────────────────────────────────────────────────────────┐
│   招待コード管理                         [+ 新規発行]       │
├─────────────────────────────────────────────────────────────┤
│  検索: [        ]  ステータス: [すべて ▼]  [検索]         │
├──────┬──────────┬────────┬────────┬────────┬─────────────┤
│ Code │ 使用状況 │ 上限   │ 有効期限│ ステータス│ 操作       │
├──────┼──────────┼────────┼────────┼────────┼─────────────┤
│ ABC1 │ 3 / 5    │ 5回    │ 未設定  │ [有効]  │ [無効化]   │
│ XYZ9 │ 10 / 無制限│ 無制限 │ 2025/12│ [有効]  │ [無効化]   │
│ TEST │ 1 / 1    │ 1回    │ 未設定  │ 無効    │ [有効化]   │
└──────┴──────────┴────────┴────────┴────────┴─────────────┘

[CSV出力]
```

### 管理者：招待コード発行フォーム（Phase 3）

```
┌─────────────────────────────────────┐
│   招待コード発行                    │
├─────────────────────────────────────┤
│                                     │
│  コード *                           │
│  ┌───────────────────────────────┐ │
│  │ ABC12345                      │ │
│  └───────────────────────────────┘ │
│  [ランダム生成]                     │
│  ※ 6〜12文字の英数字（大文字）     │
│                                     │
│  使用回数制限                       │
│  ┌───────────────────────────────┐ │
│  │ 10                            │ │
│  └───────────────────────────────┘ │
│  ※ 空欄の場合は無制限              │
│                                     │
│  有効期限                           │
│  ┌───────────────────────────────┐ │
│  │ 2025-12-31                    │ │
│  └───────────────────────────────┘ │
│  ※ 空欄の場合は無期限              │
│                                     │
│  メモ                               │
│  ┌───────────────────────────────┐ │
│  │ βテスター向け（第1期）        │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  [発行する]  [キャンセル]           │
└─────────────────────────────────────┘
```

---

## 🔒 セキュリティ考慮事項

### 1. コード推測対策

- **ランダム生成**: `SecureRandom.alphanumeric`使用
- **長さ**: 最低6文字（英数字大文字のみ = 36^6 = 2,176,782,336通り）
- **一意性**: DB制約 + バリデーション

### 2. ブルートフォース対策

- **レート制限**: Rack::Attackで登録エンドポイント制限（将来実装）
- **使用回数制限**: max_uses設定推奨
- **有効期限**: expires_at設定推奨

### 3. 権限管理

- **招待コード管理**: adminロールのみ（Pundit）
- **Userモデル**: ロール変更防止機構（既存）

### 4. データ保護

- **コードの暗号化**: 不要（公開前提、推測困難性で保護）
- **メモの暗号化**: 不要（管理者のみ閲覧、機密情報記載非推奨）

---

## 📊 想定運用シナリオ

### シナリオ1: クローズドβ初期（5名）

```ruby
# 管理者が5名分の招待コード発行
InvitationCode.create!(
  code: InvitationCode.generate_code,
  max_uses: 1,
  expires_at: 1.month.from_now,
  created_by: admin,
  memo: 'βテスター（第1期）'
)
```

### シナリオ2: クローズドβ拡大（10名追加）

```ruby
# 10名が使用できる共通コード
InvitationCode.create!(
  code: 'BETA2025',
  max_uses: 10,
  expires_at: 3.months.from_now,
  created_by: admin,
  memo: 'βテスター（第2期）'
)
```

### シナリオ3: 無期限・無制限コード（開発者用）

```ruby
# 開発・テスト用
InvitationCode.create!(
  code: 'DEVTEST',
  max_uses: nil,
  expires_at: nil,
  created_by: admin,
  memo: '開発・テスト用'
)
```

---

## 📈 将来拡張（Phase 4以降）

### 1. 招待コード使用履歴

- `invitation_code_usages` テーブル作成
- ユーザーと招待コードの中間テーブル化
- 使用日時、IPアドレス等のログ記録

### 2. 招待コードグループ管理

- `invitation_code_groups` テーブル作成
- キャンペーン別、期別のグループ管理
- グループ単位での統計表示

### 3. 分析ダッシュボード

- 招待コード別登録数グラフ
- 時系列での登録推移
- コンバージョン率分析

### 4. 自動無効化

- 有効期限到達時の自動無効化（Sidekiq）
- 使用回数上限到達時の通知

---

## ✅ 完了チェックリスト

### Phase 1: InvitationCodeモデル基盤実装

- [ ] InvitationCodeモデル作成
- [ ] マイグレーション実行
- [ ] バリデーション実装
- [ ] ビジネスロジック実装
- [ ] Model Spec（100%カバレッジ）
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] PR作成・レビュー・マージ

### Phase 2: 会員登録フロー統合

- [ ] Userモデルへのinvitation_code関連付け
- [ ] マイグレーション実行
- [ ] RegistrationsController変更
- [ ] 新規登録画面への入力欄追加
- [ ] Model/Request/System Spec
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] 招待コードなしでの登録不可確認
- [ ] PR作成・レビュー・マージ

### Phase 3: 管理者機能実装

- [ ] Admin::InvitationCodesController作成
- [ ] ビュー作成（一覧・発行フォーム）
- [ ] Pundit認可設定
- [ ] CSV出力機能
- [ ] Request/System Spec
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] CSV出力動作確認
- [ ] PR作成・レビュー・マージ

---

## 🎯 成功指標

1. **機能面**:
   - 招待コードなしでは新規登録不可
   - 管理者が招待コードを発行・管理可能
   - 使用回数・有効期限の制御が正常動作

2. **品質面**:
   - 全Spec通過（1053+ examples, 0 failures）
   - RuboCop違反なし
   - Brakeman警告なし
   - カバレッジ維持（90%以上）

3. **セキュリティ面**:
   - adminロール以外は招待コード管理不可
   - コード推測困難（SecureRandom使用）
   - バリデーションによる不正入力防止

---

**Last Updated**: 2025-10-27
**Status**: Phase 1実装準備完了
**Next Action**: Phase 1ブランチ作成 → TDD実装開始
