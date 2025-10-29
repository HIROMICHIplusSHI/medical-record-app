# Phase 7: 招待コード機能 - セキュリティレビュー

**レビュー日**: 2025-10-28
**対象ブランチ**: `feature/phase7-invitation-code-registration`
**レビュアー**: Security Engineer Agent
**ステータス**: ⚠️ 条件付き承認（改善推奨事項あり）

---

## 📊 総合評価

**セキュリティスコア**: 7.5/10
**判定**: ⚠️ 条件付き承認

Phase 7の招待コード機能実装は基本的なセキュリティ要件を満たしていますが、ブルートフォース攻撃対策とタイミング攻撃への耐性に改善の余地があります。現状でもMVP・クローズドベータ運用には十分ですが、本番公開前に推奨事項への対応が望ましいです。

---

## 🛡️ セキュリティ評価（分野別）

### 1. 認証・認可 (9/10)

**評価**: 優秀

**強み**:
- **招待コード必須化**: 新規登録時の招待コード検証が確実に機能
  ```ruby
  validates :invitation_code_input, presence: true, on: :create,
            unless: :skip_invitation_code_validation?
  ```
- **管理者権限の例外処理**: 管理者とOAuthユーザーは適切にスキップ
  ```ruby
  def skip_invitation_code_validation?
    admin? || provider.present?
  ```
- **トランザクション保証**: ユーザー作成と使用回数インクリメントのアトミック性
  ```ruby
  InvitationCode.transaction do
    self.invitation_code = @validated_invitation_code
    @validated_invitation_code.increment_used_count!
  end
  ```

**改善提案** (優先度: 低):
- OAuth認証時の招待コードスキップは妥当だが、将来的にOAuth経由でも招待コード必須化を検討すべきケースがあるかもしれない（現状は問題なし）

---

### 2. 入力検証 (8.5/10)

**評価**: 優秀

**強み**:
- **Strong Parameters**: 必要なパラメータのみ許可
  ```ruby
  devise_parameter_sanitizer.permit(:sign_up,
    keys: %i[terms_accepted privacy_accepted invitation_code_input])
  ```
- **正規表現バリデーション**: 厳密なフォーマット検証
  ```ruby
  format: { with: /\A[A-Z0-9]{6,12}\z/ }
  ```
  - `\A`, `\z`による完全一致（改行攻撃防止）
  - 英数字大文字のみ（特殊文字排除）
  - 6〜12文字の長さ制限

- **正規化処理**: 大文字変換・空白除去
  ```ruby
  normalized_code = invitation_code_input.upcase.strip
  ```
- **多層バリデーション**: DB制約 + Railsバリデーション + ビジネスロジック
  - DB: `unique: true` index
  - Rails: `uniqueness: { case_sensitive: false }`
  - モデル: `available?`メソッドによる複合判定

**テストカバレッジ**:
- 正常系: `ABC123`, `ABCDEFGH12` ✅
- 異常系: `abc123`(小文字), `AB`(短い), `ABCDEFGHIJKLM`(長い), `ABC-123`(ハイフン), `ABC 123`(スペース) ✅
- エッジケース: `  testcode  `(前後空白), `testcode`(小文字+空白) ✅

**SQLインジェクション対策**: ✅ 完璧
- ActiveRecord使用で自動エスケープ
- `find_by(code: normalized_code)`は安全なプレースホルダー使用

---

### 3. セキュリティリスク (6/10)

**評価**: 要改善

#### ✅ 対策済み

**コード推測困難性**: ✅ 優秀
- `SecureRandom.alphanumeric(8).upcase`による暗号学的乱数生成
- 8文字英数字大文字: 36^8 = 2,821,109,907,456通り（2.8兆通り）
- 重複チェック機構（`exists?(code: code)`）
- DB unique制約による二重保護

**Race Condition対策**: ✅ 優秀
- `increment!`メソッドによるアトミック更新
  ```sql
  UPDATE invitation_codes SET used_count = used_count + 1 WHERE id = ?
  ```
- トランザクション内での実行（ACID特性保証）

**Mass Assignment対策**: ✅ 完璧
- `created_by`必須バリデーションで匿名コード作成防止
- Strong Parametersによる不正パラメータ排除
- `invitation_code_input`は仮想属性（DBに直接保存されない）

#### ⚠️ 未対策・脆弱性

**1. ブルートフォース攻撃への耐性**: ⚠️ 不十分（優先度: 高）

**現状の問題**:
- Rate limiting未実装（Rack::Attack等のgem未導入）
- 連続失敗回数の制限なし
- IPアドレスベースのブロック機構なし

**攻撃シナリオ**:
```ruby
# 攻撃者が自動スクリプトで総当たり攻撃
1000.times do |i|
  post user_registration_path, params: {
    user: {
      email: "attacker#{i}@example.com",
      password: "password123",
      invitation_code_input: generate_random_code(), # AAAAAA, AAAAAB, ...
      terms_accepted: 'true',
      privacy_accepted: 'true'
    }
  }
end
```

**リスク評価**:
- **影響度**: 中（招待コードの不正取得）
- **発生確率**: 低（2.8兆通りの推測困難性）
- **総合リスク**: 中

**推奨対策**:
```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # 招待コード入力の試行回数制限（10分間に10回まで）
  throttle('registrations/invitation_code', limit: 10, period: 10.minutes) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # 同一IPからの大量登録試行ブロック（1時間に5回まで）
  throttle('registrations/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end
end
```

**2. タイミング攻撃への耐性**: ⚠️ 弱い（優先度: 中）

**現状の問題**:
```ruby
code = InvitationCode.find_by(code: normalized_code)

unless code
  errors.add(:invitation_code_input, '有効な招待コードではありません')
  return
end

unless code.available?
  add_code_unavailable_error(code)
  return
end
```

**攻撃シナリオ**:
- レスポンス時間の違いから情報を推測
  - コード存在しない: 即座にエラー（DBクエリ1回）
  - コード存在するが無効: 遅延エラー（DBクエリ1回 + `available?`チェック）
  - 攻撃者がレスポンス時間を測定し、有効なコードを絞り込む

**リスク評価**:
- **影響度**: 低（情報漏洩は限定的）
- **発生確率**: 極低（高度な攻撃技術が必要）
- **総合リスク**: 低

**推奨対策**:
```ruby
def invitation_code_must_be_valid
  return if invitation_code_input.blank?

  normalized_code = invitation_code_input.upcase.strip

  # タイミング攻撃対策：常に一定の処理時間を確保
  code = InvitationCode.find_by(code: normalized_code)
  is_valid = code&.available?

  # エラーメッセージを統一（情報漏洩防止）
  unless is_valid
    errors.add(:invitation_code_input, '無効な招待コードです')
    return
  end

  @validated_invitation_code = code
end
```

**3. 列挙攻撃（Enumeration Attack）**: ⚠️ 一部脆弱（優先度: 中）

**現状の問題**:
- エラーメッセージが詳細すぎる
  - 「有効な招待コードではありません」→ コード存在しない
  - 「無効な招待コードです」→ コード存在するが inactive
  - 「有効期限が切れています」→ コード存在するが期限切れ
  - 「使用回数の上限に達しています」→ コード存在するが上限到達

**攻撃シナリオ**:
- エラーメッセージの違いから有効なコードを推測
- 攻撃者が「無効な招待コードです」を受け取れば、そのコードが存在することを確認

**リスク評価**:
- **影響度**: 低（コード存在の確認のみ、使用はできない）
- **発生確率**: 中（簡単に実行可能）
- **総合リスク**: 低〜中

**推奨対策**:
```ruby
def add_code_unavailable_error(code)
  # 全てのエラーを統一（情報漏洩防止）
  errors.add(:invitation_code_input, '無効な招待コードです')

  # ログには詳細を記録（デバッグ用）
  Rails.logger.warn("Invitation code validation failed: code=#{code.code}, " \
                    "status=#{code.status}, expired=#{code.expired?}, " \
                    "max_uses_reached=#{code.max_uses_reached?}")
end
```

---

### 4. データ保護 (9/10)

**評価**: 優秀

**強み**:

**コード生成の安全性**: ✅ 完璧
- `SecureRandom.alphanumeric`使用（暗号学的疑似乱数生成器）
- CSPRNG（Cryptographically Secure Pseudo-Random Number Generator）準拠
- OSレベルのエントロピーソース使用（`/dev/urandom`等）

**使用回数管理のRace Condition対策**: ✅ 優秀
```ruby
def increment_used_count!
  increment!(:used_count)  # アトミック操作
end
```
- SQL: `UPDATE invitation_codes SET used_count = used_count + 1 WHERE id = ?`
- DBレベルでのロック取得（排他制御）
- トランザクション内実行で整合性保証

**テスト検証**:
```ruby
it '招待コードの使用回数がインクリメントされる' do
  expect do
    post user_registration_path, params: { user: valid_attributes }
  end.to change { valid_code.reload.used_count }.by(1)
end
```

**データベース整合性**: ✅ 完璧
- `invitation_code_id`: NULL可（既存ユーザー対応）
- FK制約: `foreign_key: true`（参照整合性保証）
- Index: `index: true`（検索性能向上）
- Dependent: `nullify`（コード削除時の安全性）

---

### 5. Brakeman警告 (10/10)

**評価**: 完璧

**現状**: ✅ 招待コード機能に関連する新規セキュリティ警告なし

**Brakemanスキャン結果**:
```
Security Warnings: 3
（全て既存のFile Access警告、招待コード機能とは無関係）
- invoices_controller.rb:83 (PDF送信)
- patient_consents_controller.rb:78, 107 (PDF送信・削除)
```

**確認事項**:
- SQL Injection: 0件 ✅
- XSS: 0件 ✅
- CSRF: 0件 ✅
- Mass Assignment: 0件 ✅
- Dangerous Send: 0件 ✅

---

## 🔍 実装詳細レビュー

### InvitationCodeモデル

**セキュリティ特性**:
```ruby
# 3層重複防止
validates :code, uniqueness: { case_sensitive: false }  # Railsレベル
add_index :invitation_codes, :code, unique: true        # DBレベル
break code unless exists?(code: code)                   # 生成時チェック

# 数値バリデーション
validates :max_uses, numericality: { greater_than: 0, allow_nil: true }
validates :used_count, numericality: { greater_than_or_equal_to: 0 }

# 権限管理
validates :created_by, presence: true  # 匿名コード作成防止
```

**ビジネスロジックの安全性**:
```ruby
def available?
  active? && !expired? && !max_uses_reached?
end

# エッジケース対応
def expired?
  expires_at.present? && expires_at < Time.current
end

def max_uses_reached?
  max_uses.present? && used_count >= max_uses
end
```

**評価**: ✅ セキュアな設計

---

### Userモデル（招待コード統合）

**バリデーション戦略**:
```ruby
# 新規登録時のみ招待コード必須
validates :invitation_code_input, presence: true, on: :create,
          unless: :skip_invitation_code_validation?

validate :invitation_code_must_be_valid, on: :create,
         unless: :skip_invitation_code_validation?

# 管理者とOAuthユーザーはスキップ
def skip_invitation_code_validation?
  admin? || provider.present?
end
```

**セキュリティ懸念**: ⚠️ OAuth認証時のスキップロジック

**現状**:
```ruby
def skip_invitation_code_validation?
  admin? || provider.present?
end
```

**潜在的リスク**:
- `provider.present?`が真になるケース:
  - Google OAuth経由のユーザー（想定通り）
  - 将来的な他のOAuthプロバイダー（想定通り）
  - **データベース直接操作で`provider`が設定された場合**（想定外）

**攻撃シナリオ**:
```ruby
# 攻撃者がコンソールアクセスを取得した場合
User.create!(
  email: "attacker@example.com",
  password: "password123",
  provider: "fake_provider",  # 手動設定
  # invitation_code_inputなし → バリデーションスキップ
  terms_accepted_at: Time.current,
  privacy_accepted_at: Time.current
)
```

**リスク評価**:
- **影響度**: 高（招待コード回避）
- **発生確率**: 極低（コンソールアクセスが必要）
- **総合リスク**: 低

**推奨対策**:
```ruby
def skip_invitation_code_validation?
  admin? || oauth_user?
end

def oauth_user?
  provider.present? && uid.present?
end
```

**理由**:
- `uid`も検証することでOAuth認証の正当性を確認
- 手動での`provider`設定だけではバリデーションスキップできない

---

### RegistrationsController

**Strong Parameters**:
```ruby
def configure_sign_up_params
  devise_parameter_sanitizer.permit(:sign_up,
    keys: %i[terms_accepted privacy_accepted invitation_code_input])
end
```

**評価**: ✅ 必要最小限のパラメータのみ許可

**セキュリティ考察**:
- `invitation_code_input`は仮想属性 → DB直接保存なし ✅
- `terms_accepted`, `privacy_accepted`はboolean値 → XSSリスクなし ✅
- `invitation_code_id`は許可していない → Mass Assignment対策 ✅

---

### 新規登録画面（View）

**入力制限**:
```erb
<%= f.text_field :invitation_code_input,
    class: "... uppercase",
    maxlength: 12 %>
```

**評価**: ✅ クライアント側バリデーション

**セキュリティ注意点**:
- `maxlength: 12`はフロントエンドのみ → サーバー側で再検証必須 ✅
- `uppercase`クラスによるCSS変換 → サーバー側で正規化必須 ✅
- 両方とも実装済み（`normalized_code = invitation_code_input.upcase.strip`）

---

## 📝 テスト品質

### カバレッジ

**Model Spec**: 38 examples, 0 failures ✅
- バリデーション: 13 examples
- ビジネスロジック: 20 examples
- スコープ: 3 examples
- Enum: 1 example
- アソシエーション: 2 examples

**Request Spec**: 14 examples, 0 failures ✅
- 正常系: 4 examples
- 正規化: 3 examples
- 異常系（招待コード）: 5 examples
- 異常系（規約）: 2 examples

**System Spec**: 16 examples（jsテスト含む） ✅
- UI表示: 7 examples
- 登録処理: 9 examples

**総合カバレッジ**: 68 examples, 0 failures ✅

### セキュリティテスト

**テスト済み攻撃パターン**:
1. 存在しない招待コード ✅
2. 無効（inactive）な招待コード ✅
3. 期限切れの招待コード ✅
4. 使用回数上限到達の招待コード ✅
5. 招待コードなし ✅
6. 小文字・空白の正規化 ✅

**未テストの攻撃パターン**:
1. ⚠️ 連続大量試行（ブルートフォース）
2. ⚠️ タイミング攻撃
3. ⚠️ 並行アクセスによるRace Condition（理論的には対策済みだがテスト未実装）

**推奨追加テスト**:
```ruby
# spec/requests/users/registrations_spec.rb
context 'セキュリティ: Race Condition対策' do
  it '並行登録時に使用回数が正確にインクリメントされる' do
    threads = 5.times.map do
      Thread.new do
        post user_registration_path, params: {
          user: valid_attributes.merge(email: "user#{rand(10000)}@example.com")
        }
      end
    end
    threads.each(&:join)

    expect(valid_code.reload.used_count).to eq(5)
  end
end
```

---

## ⚠️ 改善推奨事項

### 優先度: 高（本番公開前に対応推奨）

#### 1. Rate Limiting実装

**対応内容**: Rack::Attack導入
```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  throttle('registrations/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  throttle('registrations/invitation', limit: 10, period: 10.minutes) do |req|
    if req.path == '/users' && req.post?
      req.params['user']&.[]('invitation_code_input')
    end
  end
end
```

**工数**: 0.5日
**リスク軽減**: 中 → 高

---

### 優先度: 中（Phase 8〜9で対応）

#### 2. タイミング攻撃対策

**対応内容**: レスポンス時間の均一化
```ruby
def invitation_code_must_be_valid
  return if invitation_code_input.blank?

  normalized_code = invitation_code_input.upcase.strip
  code = InvitationCode.find_by(code: normalized_code)
  is_valid = code&.available?

  # 統一エラーメッセージ
  unless is_valid
    errors.add(:invitation_code_input, '無効な招待コードです')
    return
  end

  @validated_invitation_code = code
end
```

**工数**: 0.25日
**リスク軽減**: 低 → 低（理論的な対策）

---

#### 3. OAuthバリデーションスキップロジック強化

**対応内容**: `uid`も検証
```ruby
def skip_invitation_code_validation?
  admin? || oauth_authenticated?
end

def oauth_authenticated?
  provider.present? && uid.present?
end
```

**工数**: 0.25日
**リスク軽減**: 極低 → ゼロ

---

#### 4. エラーメッセージ統一（列挙攻撃対策）

**対応内容**: 全エラーを「無効な招待コードです」に統一
```ruby
def add_code_unavailable_error(code)
  errors.add(:invitation_code_input, '無効な招待コードです')

  # ログには詳細を記録
  Rails.logger.warn("Invalid invitation code: #{code.id}")
end
```

**工数**: 0.25日
**リスク軽減**: 低〜中 → 低

---

### 優先度: 低（将来検討）

#### 5. 招待コード使用履歴の記録

**対応内容**: 監査ログ機能
```ruby
class InvitationCodeUsageLog < ApplicationRecord
  belongs_to :invitation_code
  belongs_to :user

  validates :ip_address, presence: true
  validates :user_agent, presence: true
end

# app/models/user.rb
after_create :log_invitation_code_usage

def log_invitation_code_usage
  return unless invitation_code

  InvitationCodeUsageLog.create!(
    invitation_code: invitation_code,
    user: self,
    ip_address: Current.ip_address,
    user_agent: Current.user_agent
  )
end
```

**工数**: 1日
**メリット**: 不正使用の検知・追跡

---

#### 6. 招待コード入力失敗のロギング

**対応内容**: 失敗試行の記録
```ruby
# app/models/user.rb
def invitation_code_must_be_valid
  # ...existing code...

  unless is_valid
    Rails.logger.security.warn(
      "Invalid invitation code attempt: " \
      "code=#{normalized_code}, " \
      "ip=#{Current.ip_address}, " \
      "user_agent=#{Current.user_agent}"
    )
    errors.add(:invitation_code_input, '無効な招待コードです')
    return
  end
end
```

**工数**: 0.5日
**メリット**: 攻撃パターンの分析

---

## ✅ マージ判定

### 判定: ⚠️ 条件付き承認

**マージ条件**:
1. **必須対応なし**: 現状の実装でMVP・クローズドベータ運用は可能
2. **推奨対応**: Phase 8〜9でRate Limiting実装

**理由**:

**承認理由**:
1. 基本的なセキュリティ要件を満たしている ✅
2. テストカバレッジが十分（68 examples, 0 failures） ✅
3. Brakeman警告なし ✅
4. Race Condition対策済み ✅
5. SQLインジェクション対策済み ✅
6. Mass Assignment対策済み ✅

**条件付き理由**:
1. ⚠️ Rate Limiting未実装（ブルートフォース攻撃に脆弱）
2. ⚠️ タイミング攻撃への耐性が弱い
3. ⚠️ エラーメッセージが詳細すぎる（列挙攻撃のリスク）

**リスク評価**:
- **現時点のリスク**: 低〜中
- **クローズドベータ運用**: 問題なし ✅
- **本番公開**: Rate Limiting実装後が望ましい ⚠️

---

## 📊 セキュリティスコア詳細

| 評価項目 | スコア | 配点 | 備考 |
|---------|--------|------|------|
| **認証・認可** | 9 | 10 | トランザクション保証、権限管理が優秀 |
| **入力検証** | 8.5 | 10 | 正規表現、正規化、多層バリデーション |
| **セキュリティリスク** | 6 | 10 | Rate Limiting未実装、タイミング攻撃 |
| **データ保護** | 9 | 10 | SecureRandom使用、Race Condition対策 |
| **Brakeman警告** | 10 | 10 | 招待コード関連の新規警告なし |

**総合スコア**: 42.5/50 = **8.5/10**

（上記「7.5/10」は安全側の評価、詳細分析では8.5/10）

---

## 🎯 次のステップ

### Phase 7完了後のアクション

1. **PRマージ**: `feature/phase7-invitation-code-registration` → `main`
2. **動作確認**: クローズドベータ環境での登録テスト
3. **Phase 8実装開始**: Rate Limiting導入（Rack::Attack）
4. **Phase 9以降**: タイミング攻撃対策、エラーメッセージ統一

### 推奨作業順序（Phase 8〜9）

**Phase 8: セキュリティ強化（1.5日）**
1. Rack::Attack導入（0.5日）
2. タイミング攻撃対策（0.25日）
3. OAuthバリデーション強化（0.25日）
4. エラーメッセージ統一（0.25日）
5. テスト追加（0.25日）

**Phase 9: 監査ログ（1日）**
1. InvitationCodeUsageLogモデル作成（0.5日）
2. 失敗試行のロギング（0.25日）
3. 管理画面での履歴表示（0.25日）

---

## 📚 参考資料

### セキュリティベストプラクティス

- [OWASP Top 10 2021](https://owasp.org/www-project-top-ten/)
  - A01:2021 – Broken Access Control
  - A03:2021 – Injection
  - A04:2021 – Insecure Design
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Rack::Attack Documentation](https://github.com/rack/rack-attack)

### タイミング攻撃

- [Timing Attack - Wikipedia](https://en.wikipedia.org/wiki/Timing_attack)
- [Rails ActiveSupport::SecurityUtils.secure_compare](https://api.rubyonrails.org/classes/ActiveSupport/SecurityUtils.html#method-c-secure_compare)

### Rate Limiting

- [Rack::Attack Best Practices](https://github.com/rack/rack-attack/wiki/Example-Configuration)
- [Cloudflare Rate Limiting](https://developers.cloudflare.com/waf/rate-limiting-rules/)

---

**レビュー完了日**: 2025-10-28
**承認者**: Security Engineer Agent
**次回レビュー**: Phase 8（セキュリティ強化）完了時

---

## 🏆 総評

Phase 7の招待コード機能実装は、**基本的なセキュリティ要件を満たした高品質な実装**です。

**特に優れている点**:
1. ✅ 暗号学的に安全な招待コード生成（SecureRandom）
2. ✅ Race Condition対策（アトミック更新、トランザクション）
3. ✅ 多層バリデーション（DB制約 + Rails + ビジネスロジック）
4. ✅ 包括的なテストスイート（68 examples, 0 failures）
5. ✅ Brakeman警告なし

**改善が望ましい点**:
1. ⚠️ Rate Limiting未実装（ブルートフォース攻撃に脆弱）
2. ⚠️ タイミング攻撃への耐性が弱い
3. ⚠️ エラーメッセージが詳細すぎる（列挙攻撃のリスク）

**ただし、これらは本番公開前に対応すべき項目であり、クローズドベータ運用では大きな問題になりません。**

現時点での総合評価は**「条件付き承認」**ですが、推奨事項への対応により**「完全承認」**レベルに到達可能です。

自信を持ってマージし、Phase 8でのセキュリティ強化を進めてください！

**セキュリティスコア: 7.5/10（安全側評価）〜8.5/10（詳細評価）**
**判定: ⚠️ 条件付き承認**
