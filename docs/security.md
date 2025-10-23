# セキュリティ仕様書

**プロジェクト名**: フリーランスアートメイク施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0

---

## 1. 暗号化仕様

### 1.1 Active Record Encryption（Phase 2で実装）

Rails 7標準の暗号化機能を使用し、患者の個人情報を保護します。

#### 暗号化アルゴリズム
- **方式**: AES-256-GCM
- **キー管理**: Rails credentials（`config/credentials.yml.enc`）
- **キーローテーション**: 対応

#### 暗号化対象フィールド

**Patient（患者）**
```ruby
encrypts :name                    # 氏名
encrypts :date_of_birth           # 生年月日
encrypts :phone                   # 電話番号
encrypts :email, deterministic: true  # メールアドレス（検索可能）
encrypts :address                 # 住所
encrypts :emergency_contact       # 緊急連絡先
```

**Questionnaire（問診票）**
```ruby
encrypts :medical_history         # 既往歴
encrypts :current_medication      # 服薬状況
encrypts :desired_treatment       # 施術希望部位
encrypts :concerns                # 気になる症状
encrypts :notes                   # 自由記述
```

**Consent（同意書）**
```ruby
encrypts :patient_signature       # 患者署名画像データ
```

#### 検索可能暗号化（Deterministic Encryption）

メールアドレスは検索が必要なため、決定論的暗号化を使用：
```ruby
encrypts :email, deterministic: true
```

- 同じ平文は同じ暗号文になる
- データベースでの検索・一意性制約が可能
- 他のフィールドより若干セキュリティレベルが下がるが実用上問題なし

### 1.2 セットアップ手順

#### 暗号化キーの生成
```bash
bin/rails db:encryption:init
```

生成されたキーは自動的に `config/credentials.yml.enc` に保存されます。

#### 環境変数（本番環境）
```bash
# RAILS_MASTER_KEY を環境変数で設定
RAILS_MASTER_KEY=<your_master_key>
```

---

## 2. 電子署名仕様（Phase 4で実装）

### 2.1 簡易的な電子署名

電子署名法の完全準拠ではなく、医療現場で実用的な簡易署名を実装。

#### 記録内容
```ruby
- 署名画像データ（手書き署名・Canvas APIで取得）
- 署名日時（タイムスタンプ）
- 署名者情報（患者ID、氏名）
- IPアドレス
- User Agent
- 署名前の文書ハッシュ値（改ざん検知用）
```

#### ハッシュ計算
```ruby
def calculate_document_hash
  content = "#{patient.name}#{consent_template.content}#{created_at}"
  Digest::SHA256.hexdigest(content)
end
```

### 2.2 署名の法的位置づけ

- 美容医療の同意書は「診療契約の合意」の証明が主目的
- 電子署名法の厳密な準拠は不要
- 重要なのは「本人が同意した証拠」が残ること
- 訴訟時にも十分な証拠能力を持つ

---

## 3. アクセス制御

### 3.1 認証（Authentication）

**Devise + OmniAuth (Google)**

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
```

すべてのコントローラーで認証を必須化。

### 3.2 認可（Authorization）

**ユーザーごとのデータ分離**

```ruby
# 正しい例
def index
  @patients = current_user.patients
end

# 間違った例（全ユーザーのデータが見える）
def index
  @patients = Patient.all
end
```

**before_actionでの所有者チェック**

```ruby
class PatientsController < ApplicationController
  before_action :set_patient, only: [:show, :edit, :update, :destroy]

  private

  def set_patient
    @patient = current_user.patients.find_by(id: params[:id])
    return if @patient

    redirect_to patients_path, alert: 'アクセス権限がありません。'
  end
end
```

### 3.3 Strong Parameters

```ruby
def patient_params
  params.require(:patient).permit(
    :name, :date_of_birth, :gender, :phone, :email, :address, :emergency_contact
  )
end
```

許可されたパラメータのみを受け付け、マスアサインメント攻撃を防止。

---

## 4. HTTPS/SSL

### 4.1 本番環境

Render.comの標準機能で自動的にHTTPS化。

```ruby
# config/environments/production.rb
config.force_ssl = true
```

すべての通信を強制的にHTTPS化。

### 4.2 Secure Cookie

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,  # 本番環境ではHTTPSのみ
  httponly: true,                 # JavaScriptからアクセス不可
  same_site: :lax                 # CSRF対策
```

---

## 5. CSRF対策

### 5.1 Rails標準機能

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
```

すべてのPOST/PUT/PATCH/DELETE リクエストでCSRFトークンを検証。

### 5.2 フォーム

```erb
<%= form_with model: @patient do |f| %>
  <%# CSRFトークンが自動挿入される %>
<% end %>
```

---

## 6. SQLインジェクション対策

### 6.1 パラメータ化クエリ

```ruby
# 正しい例（プレースホルダー使用）
Patient.where("name LIKE ?", "%#{params[:q]}%")

# 間違った例（SQLインジェクションの危険）
Patient.where("name LIKE '%#{params[:q]}%'")
```

Active Recordは自動的にエスケープを行います。

---

## 7. XSS対策

### 7.1 自動エスケープ

ERBテンプレートでは自動的にHTMLエスケープされます。

```erb
<%# 自動エスケープされる %>
<%= @patient.name %>

<%# エスケープを無効化（危険！） %>
<%== @patient.name %>
```

### 7.2 Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline
end
```

---

## 8. ファイルアップロードセキュリティ

### 8.1 画像アップロード検証

```ruby
class MedicalRecord < ApplicationRecord
  validate :photos_validation

  private

  def photos_validation
    return unless photos.attached?

    if photos.count > 5
      errors.add(:photos, '画像は最大5枚までアップロード可能です')
    end

    photos.each do |photo|
      unless photo.content_type.in?(%w[image/jpeg image/png])
        errors.add(:photos, 'JPEG または PNG 形式のみアップロード可能です')
      end

      if photo.byte_size > 10.megabytes
        errors.add(:photos, '画像サイズは10MB以下にしてください')
      end
    end
  end
end
```

### 8.2 PDFアップロード検証（Phase 4）

```ruby
class Consent < ApplicationRecord
  validate :pdf_validation

  private

  def pdf_validation
    return unless pdf_file.attached?

    unless pdf_file.content_type == 'application/pdf'
      errors.add(:pdf_file, 'PDF形式のみアップロード可能です')
    end

    if pdf_file.byte_size > 20.megabytes
      errors.add(:pdf_file, 'PDFサイズは20MB以下にしてください')
    end
  end
end
```

---

## 9. 環境変数管理

### 9.1 機密情報の管理

機密情報は環境変数またはRails credentialsで管理：

```bash
# .env（ローカル開発用・gitignore必須）
DATABASE_URL=postgresql://...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

### 9.2 本番環境

Render.comの環境変数機能で設定。

---

## 10. 監査とロギング

### 10.1 最低限の履歴管理（Phase 2-4で実装）

**Consentモデル**
```ruby
- created_at: 同意書作成日時
- signed_at: 署名日時
- pdf_generated_at: PDF生成日時
- status: ステータス（下書き/署名済み/PDF化済み）
```

### 10.2 Railsログ

```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id]
```

本番環境では INFO レベル以上のログを記録。

---

## 11. 脆弱性スキャン

### 11.1 Brakeman静的セキュリティスキャン（Phase 4-04で実装 ✅）

**概要**:
Brakemanは、Railsアプリケーション専用の静的セキュリティスキャナーです。ソースコードを解析し、SQLインジェクション、XSS、マスアサインメントなど84種類のセキュリティ脆弱性を検出します。

#### 実装内容

**1. Brakeman導入**
```bash
# Gemfile（development/testグループ）
gem 'brakeman', '~> 6.0', require: false

# インストール
bundle install

# 手動スキャン実行
bundle exec brakeman
```

**2. 設定ファイル（`.brakeman.yml`）**
```yaml
:app_path: "."
:rails: true
:skip_checks: []
:skip_files:
  - node_modules/**/*
  - vendor/**/*
  - tmp/**/*
:min_confidence: 2  # すべての警告を表示（医療アプリのため厳密）
:github_repo: HIROMICHIplusSHI/medical-record-app
```

**3. CI統合（GitHub Actions）**

`.github/workflows/brakeman.yml` で以下を自動実行：
- **PR作成時**: セキュリティスキャン実行
- **mainブランチへのpush**: セキュリティスキャン実行
- **定期スキャン**: 毎週月曜日 9:00 JST

```yaml
name: Brakeman Security Scan

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'  # 毎週月曜日 00:00 UTC

jobs:
  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Run Brakeman
        run: bundle exec brakeman --format json --output brakeman-report.json
      - name: Check for High/Medium warnings
        run: |
          # High/Medium警告が1件でもあればビルド失敗
          if [ $(jq '.warnings | map(select(.confidence == "High" or .confidence == "Medium")) | length' brakeman-report.json) -gt 0 ]; then
            exit 1
          fi
```

**4. PR自動コメント機能**

スキャン結果を自動的にPRにコメント：
```markdown
## 🔒 Brakeman Security Scan Results

| Confidence | Count |
|------------|-------|
| 🔴 High | 0 |
| 🟡 Medium | 0 |
| 🟢 Weak | 0 |
| **Total** | **0** |

✅ **No security warnings found!**
```

#### 初回スキャン結果（2025-10-14）

```json
{
  "security_warnings": 1,
  "warnings": [
    {
      "warning_type": "Unmaintained Dependency",
      "confidence": "High",
      "message": "Support for Rails 7.1.5.2 ended on 2025-10-01"
    }
  ]
}
```

**結果**:
- ✅ **XSS脆弱性**: 0件（Phase 4-03で完全修正済み）
- ✅ **SQL Injection**: 0件
- ✅ **マスアサインメント**: 0件
- ✅ **その他セキュリティ警告**: 0件
- ⚠️ **Rails 7.1 EOL**: 1件（Phase 5でRails 7.2へアップグレード予定）

#### ビルド失敗条件

以下の場合、CIビルドが失敗します：
- **High confidence** 警告が1件以上
- **Medium confidence** 警告が1件以上

Weak confidence警告は情報提供のみで、ビルドは通過します。

#### レポート保存

- **JSON**: `brakeman-report.json`（gitignore済み）
- **HTML**: `brakeman-report.html`（gitignore済み）
- **CI Artifacts**: GitHub Actionsで30日間保持

### 11.2 依存関係の監視（今後実装予定）

```bash
# Bundler Audit（Gemの脆弱性チェック）
bundle audit check --update
```

GitHub Actionsで自動実行予定。

---

## 12. バックアップとリカバリ

### 12.1 データベースバックアップ

Render.comの自動バックアップ機能：
- 日次バックアップ: 7日間保持
- 週次バックアップ: 4週間保持

### 12.2 ファイルバックアップ

Active Storageで使用するCloudflare R2/AWS S3のバージョニング機能を有効化。

---

## 13. インシデント対応

### 13.1 情報漏洩発生時の対応手順

1. **即時対応**
   - サービス停止の判断
   - 原因の特定
   - 影響範囲の調査

2. **通知**
   - 該当ユーザーへの連絡
   - 必要に応じて個人情報保護委員会への報告

3. **復旧**
   - 脆弱性の修正
   - サービス再開
   - 再発防止策の実施

4. **事後対応**
   - インシデントレポート作成
   - セキュリティ対策の見直し

---

## 14. セキュリティチェックリスト

### Phase 2実装時
- [ ] Active Record Encryptionの設定
- [ ] 暗号化キーの生成と安全な管理
- [ ] Patient/Questionnaireの暗号化フィールド実装
- [ ] アクセス制御の実装とテスト
- [ ] Strong Parametersの設定

### Phase 4実装時
- [ ] 電子署名の実装
- [ ] 署名データの暗号化
- [ ] PDFアップロード検証
- [ ] ハッシュ値による改ざん検知

### 本番デプロイ前
- [ ] HTTPS強制化の確認
- [ ] 環境変数の設定確認
- [ ] バックアップ設定の確認
- [ ] bundle audit 実行
- [ ] brakeman 実行
- [ ] RuboCop Security cops 実行

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: Phase 2実装開始時
