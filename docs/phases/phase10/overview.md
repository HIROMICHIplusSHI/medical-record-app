# Phase 10: 本番デプロイ

**作成日**: 2025-10-21
**最終更新**: 2025-10-21
**目標**: Render環境への本番デプロイと運用開始

**前提**: Phase 9（パフォーマンス改善・UI/UX改善）完了後に実施

---

## 🎯 Phase 10の目的

開発が完了したアプリケーションをRender環境にデプロイし、本番運用を開始する。

### 主な作業
1. **Render環境構築**: Web Service, PostgreSQL, R2設定
2. **環境変数設定**: 本番環境の設定
3. **データベースセットアップ**: マイグレーション実行
4. **動作確認**: E2Eテスト、本番環境での確認
5. **運用準備**: バックアップ、監視、ドキュメント

---

## 📋 実装予定（工数: 2-3日）

### Phase 10-A: Render環境構築（0.5-1日）

**実施内容**:
1. **Renderアカウント作成**
   - Professional Plan ($7/月〜) の契約

2. **PostgreSQLデータベース作成**
   - PostgreSQL 14+ インスタンス作成
   - データベースURL取得

3. **Cloudflare R2設定**
   - バケット作成
   - Access Key / Secret Key 取得
   - CORS設定

4. **Web Service作成**
   - GitHubリポジトリ連携
   - ビルドコマンド設定: `./bin/render-build.sh`
   - 起動コマンド設定: `bundle exec puma -C config/puma.rb`

---

### Phase 10-B: 環境変数設定（0.5日）

**必須環境変数**:
```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<config/master.keyの内容>
DATABASE_URL=<RenderのPostgreSQL URL>

# Cloudflare R2 (Active Storage)
R2_ACCESS_KEY_ID=<R2 Access Key>
R2_SECRET_ACCESS_KEY=<R2 Secret Key>
R2_ENDPOINT=<R2 Endpoint URL>
R2_BUCKET_NAME=<バケット名>

# Google OAuth（必要に応じて）
GOOGLE_CLIENT_ID=<Client ID>
GOOGLE_CLIENT_SECRET=<Client Secret>

# その他
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
```

**設定方法**:
- Renderダッシュボード > Environment > Environment Variables

---

### Phase 10-C: デプロイ実行（0.5日）

**実施内容**:
1. **render.yaml確認**
   ```yaml
   services:
     - type: web
       name: medical-record-app
       env: ruby
       buildCommand: "./bin/render-build.sh"
       startCommand: "bundle exec puma -C config/puma.rb"
       envVars:
         - key: DATABASE_URL
           fromDatabase:
             name: medical-record-db
             property: connectionString
         - key: RAILS_MASTER_KEY
           sync: false
   databases:
     - name: medical-record-db
       databaseName: medical_record_production
       user: medical_record_user
   ```

2. **初回デプロイ**
   - GitHubリポジトリ連携
   - mainブランチへのプッシュで自動デプロイ

3. **マイグレーション実行**
   - `bin/render-build.sh`で自動実行
   - 確認: Renderログで `rails db:migrate` 成功確認

---

### Phase 10-D: 動作確認（0.5-1日）

**確認項目**:

1. **基本動作**
   - [ ] ログイン・ログアウト
   - [ ] 会員登録（紹介コード）
   - [ ] ホームページ表示

2. **主要機能**
   - [ ] カルテ作成・編集・削除
   - [ ] 患者登録・編集・削除
   - [ ] 施術場所登録・編集・削除
   - [ ] 請求書生成・PDF出力
   - [ ] 同意書作成・署名・PDF出力

3. **管理者機能**
   - [ ] 管理者ダッシュボード
   - [ ] ユーザー管理
   - [ ] お知らせ管理
   - [ ] 紹介コード管理

4. **ファイルアップロード**
   - [ ] カルテ画像アップロード（Cloudflare R2）
   - [ ] 画像表示確認
   - [ ] 画像削除確認

5. **パフォーマンス**
   - [ ] Lighthouse測定（本番環境）
   - [ ] ページロード時間確認
   - [ ] N+1クエリ確認（ログ）

---

### Phase 10-E: 運用準備（0.5日）

**実施内容**:

1. **管理者ユーザー作成**
   ```bash
   # Render Shell経由
   rails runner "User.create!(email: 'admin@example.com', password: 'SecurePassword123', role: :admin)"
   ```

2. **紹介コード発行**
   - 管理者画面から初期紹介コード発行

3. **バックアップ設定**
   - Render PostgreSQLの自動バックアップ確認
   - バックアップスケジュール設定

4. **監視設定**
   - Renderの自動監視（デフォルト有効）
   - Sentry設定（Phase 9で導入した場合）

5. **ドキュメント整備**
   - デプロイ手順書作成
   - 運用マニュアル作成
   - トラブルシューティングガイド作成

---

## 🎯 マイルストーン達成条件

### デプロイ
- [ ] Render環境構築完了
- [ ] 環境変数設定完了
- [ ] デプロイ成功（自動デプロイ確認）
- [ ] マイグレーション完了

### 動作確認
- [ ] 全主要機能の動作確認完了
- [ ] ファイルアップロード動作確認完了
- [ ] パフォーマンス確認完了（Lighthouse 90以上）

### 運用準備
- [ ] 管理者ユーザー作成完了
- [ ] 初期紹介コード発行完了
- [ ] バックアップ設定完了
- [ ] 監視設定完了（Render + Sentry）
- [ ] ドキュメント整備完了

---

## 📝 本番環境URL

**本番URL**: `https://<your-app>.onrender.com`

※ カスタムドメイン設定は別途検討

---

## 🚨 トラブルシューティング

### デプロイ失敗時

1. **ビルドエラー**
   - Renderログ確認
   - Gemfile.lock確認
   - bin/render-build.sh確認

2. **マイグレーションエラー**
   - DATABASE_URL確認
   - db/schema.rb確認
   - ログ確認

3. **環境変数エラー**
   - RAILS_MASTER_KEY確認
   - 必須環境変数の設定確認

### 起動エラー時

1. **Puma起動失敗**
   - config/puma.rb確認
   - PORT環境変数確認（Render自動設定）

2. **データベース接続エラー**
   - DATABASE_URL確認
   - PostgreSQLステータス確認

### ファイルアップロードエラー

1. **R2接続エラー**
   - R2環境変数確認
   - CORS設定確認
   - バケット存在確認

---

## 📚 参考資料

- [Render公式ドキュメント](https://render.com/docs)
- [Rails本番環境設定ガイド](https://railsguides.jp/configuring.html#production環境)
- [Cloudflare R2ドキュメント](https://developers.cloudflare.com/r2/)

---

**次のステップ**: Phase 9完了後、Phase 10-Aから実施開始

**作成者**: Claude
**最終更新**: 2025-10-21
