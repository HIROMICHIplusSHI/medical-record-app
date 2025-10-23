# Cloudflare R2 セットアップガイド

**プロジェクト名**: フリーランスアートメイク施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0

---

## 1. Cloudflare R2 とは

### 1.1 概要

Cloudflare R2 は、AWS S3 互換のオブジェクトストレージサービスです。

**最大の特徴:**
- ✅ **エグレス（データ転送）料金が完全無料**
- ✅ S3互換API（Active Storageで簡単に使える）
- ✅ 10GB ストレージ無料
- ✅ Cloudflare CDN統合で高速配信

### 1.2 料金（このプロジェクトの場合）

| 項目 | 無料枠 | このプロジェクトでの推定 |
|------|--------|----------------------|
| ストレージ | 10GB | 月50-300MB（**約2-3年分**） |
| Class A 操作（書込） | 100万リクエスト/月 | 月50-100リクエスト |
| Class B 操作（読取） | 1万リクエスト/日 | 月数百リクエスト |
| エグレス | **完全無料** | 無制限 |

**結論: このプロジェクトなら完全無料で運用可能** 🎉

---

## 2. Cloudflare R2 アカウント作成

### Step 1: Cloudflare アカウント作成

1. https://cloudflare.com/ にアクセス
2. 「Sign Up」をクリック
3. メールアドレスとパスワードを入力して登録
4. メール認証を完了

### Step 2: R2 有効化

1. Cloudflare ダッシュボードにログイン
2. 左サイドバーから「R2」を選択
3. 「Purchase R2」をクリック
   - **無料プラン（Workers Free）を選択**
   - クレジットカード登録が必要（無料枠超過後の課金用、通常は請求されない）

---

## 3. R2 バケット作成

### Step 1: バケット作成

1. R2 ダッシュボードで「Create bucket」をクリック
2. バケット名を入力（例: `medical-record-app-production`）
   - グローバルでユニークな名前が必要
   - 小文字、数字、ハイフンのみ使用可能
3. ロケーション: **Automatic** を選択
4. 「Create bucket」をクリック

### Step 2: CORS 設定

Active Storage で画像を直接アップロードする場合、CORS設定が必要です。

1. 作成したバケットを選択
2. 「Settings」タブをクリック
3. 「CORS Policy」セクションで「Add CORS policy」をクリック
4. 以下のJSON を入力:

```json
[
  {
    "AllowedOrigins": [
      "https://your-app-domain.com",
      "http://localhost:3000"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag"
    ],
    "MaxAgeSeconds": 3000
  }
]
```

**注意:**
- `https://your-app-domain.com` を実際のドメインに置き換える
- 開発時は `http://localhost:3000` も含める

5. 「Save」をクリック

---

## 4. API トークン作成

### Step 1: R2 API トークン生成

1. R2 ダッシュボードで「Manage R2 API Tokens」をクリック
2. 「Create API token」をクリック
3. トークン設定:
   - **Token name**: `medical-record-app-token`（任意の名前）
   - **Permissions**:
     - ✅ Object Read & Write（読み書き両方）
   - **TTL**: Never expire（期限なし）
   - **Bucket**: 作成したバケットを選択
4. 「Create API Token」をクリック

### Step 2: 認証情報をコピー

⚠️ **重要: この画面は一度しか表示されません！必ずコピーして保存してください。**

表示される情報:
```
Access Key ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Secret Access Key: yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
Jurisdiction-specific endpoint for S3 clients: https://xxxxxxxxx.r2.cloudflarestorage.com
```

これらを安全な場所にコピーして保存してください。

---

## 5. Rails アプリへの統合

### Step 1: 環境変数設定

`.env` ファイルに以下を追加:

```bash
# .env

# Cloudflare R2
R2_ACCESS_KEY_ID=<Access Key ID>
R2_SECRET_ACCESS_KEY=<Secret Access Key>
R2_ENDPOINT=<Endpoint URL>  # 例: https://xxxxxxxxx.r2.cloudflarestorage.com
R2_BUCKET_NAME=medical-record-app-production
```

### Step 2: storage.yml 確認

`config/storage.yml` が以下のようになっているか確認:

```yaml
# config/storage.yml

cloudflare:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  endpoint: <%= ENV['R2_ENDPOINT'] %>
  region: auto
  bucket: <%= ENV['R2_BUCKET_NAME'] %>
  force_path_style: true
```

### Step 3: 本番環境設定

`config/environments/production.rb`:

```ruby
# config/environments/production.rb

config.active_storage.service = :cloudflare
```

---

## 6. 動作確認

### 開発環境でテスト

#### Step 1: Rails コンソールで確認

```bash
rails console
```

```ruby
# Active Storage が正しく設定されているか確認
ActiveStorage::Blob.service

# => #<ActiveStorage::Service::S3Service:0x... @bucket="medical-record-app-production">

# テスト画像をアップロード
user = User.first
blob = ActiveStorage::Blob.create_and_upload!(
  io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
  filename: 'test.jpg',
  content_type: 'image/jpeg'
)

# アップロード成功を確認
blob.persisted? # => true
blob.service_url # => R2のURLが返る
```

#### Step 2: ブラウザで確認

1. アプリを起動: `rails s`
2. カルテ作成画面で画像をアップロード
3. アップロードが成功することを確認
4. Cloudflare R2 ダッシュボードでバケット内にファイルが存在することを確認

---

## 7. 本番環境デプロイ

### Render への環境変数設定

1. Render ダッシュボードにログイン
2. アプリを選択
3. 「Environment」タブをクリック
4. 以下の環境変数を追加:

```
R2_ACCESS_KEY_ID=<Access Key ID>
R2_SECRET_ACCESS_KEY=<Secret Access Key>
R2_ENDPOINT=<Endpoint URL>
R2_BUCKET_NAME=medical-record-app-production
```

5. 「Save Changes」をクリック
6. アプリを再デプロイ

---

## 8. トラブルシューティング

### 問題 1: アップロード時に CORS エラー

**症状:**
```
Access to fetch at 'https://xxxxx.r2.cloudflarestorage.com/...' has been blocked by CORS policy
```

**解決法:**
1. R2 バケットの CORS 設定を確認
2. `AllowedOrigins` に本番ドメインが含まれているか確認
3. `AllowedMethods` に `PUT` が含まれているか確認

### 問題 2: 接続エラー

**症状:**
```
Aws::S3::Errors::InvalidAccessKeyId
```

**解決法:**
1. 環境変数が正しく設定されているか確認
   ```bash
   rails console
   ENV['R2_ACCESS_KEY_ID']
   ENV['R2_SECRET_ACCESS_KEY']
   ENV['R2_ENDPOINT']
   ```
2. API トークンが有効か確認（Cloudflare ダッシュボード）
3. バケット名が正しいか確認

### 問題 3: 画像が表示されない

**症状:**
- アップロードは成功するが、ブラウザで画像が表示されない

**解決法:**
1. R2 バケットの「Settings」で「Public Access」が有効か確認
2. または、Active Storage の Direct Upload を使用
3. 画像URLが正しく生成されているか確認:
   ```ruby
   blob.service_url(expires_in: 5.minutes)
   ```

---

## 9. セキュリティベストプラクティス

### 9.1 API トークンの管理

- ✅ **絶対に Git にコミットしない**
- ✅ `.env` を `.gitignore` に追加
- ✅ 本番環境では環境変数として設定
- ✅ 定期的にトークンをローテーション

### 9.2 バケットのアクセス制御

- ✅ 必要最小限の権限のみ付与
- ✅ 公開バケットにしない（Direct Upload使用）
- ✅ 署名付きURLを使用（Active Storage標準）

### 9.3 ファイルサイズ制限

`config/initializers/active_storage.rb`:

```ruby
# config/initializers/active_storage.rb

Rails.application.config.active_storage.max_file_size = 10.megabytes
```

---

## 10. パフォーマンス最適化

### 10.1 Cloudflare CDN 統合

R2 は Cloudflare CDN と統合できます。

1. R2 バケットの「Settings」
2. 「Custom Domains」セクションで独自ドメインを設定
3. 自動的に CDN が有効化され、世界中で高速アクセス

### 10.2 画像最適化

Active Storage の Variant 機能を使用:

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  has_many_attached :photos

  # サムネイル生成
  def thumbnail
    photos.first.variant(resize_to_limit: [200, 200])
  end

  # 表示用サイズ
  def display_image
    photos.first.variant(resize_to_limit: [800, 800])
  end
end
```

ビューで使用:

```erb
<%# app/views/medical_records/show.html.erb %>
<%= image_tag @medical_record.thumbnail %>
<%= image_tag @medical_record.display_image %>
```

---

## 11. 監視とメンテナンス

### 11.1 使用量の確認

1. Cloudflare ダッシュボード → R2
2. 「Usage」タブで以下を確認:
   - ストレージ使用量
   - リクエスト数
   - 転送量

### 11.2 アラート設定

無料枠に近づいたらアラートを受け取る設定（任意）:

1. Cloudflare ダッシュボード → Notifications
2. R2 使用量のアラートを設定
3. 90% に達したら通知

---

## 12. 代替案への移行

将来的に AWS S3 や Backblaze B2 に移行する場合:

### AWS S3 への移行

1. `config/storage.yml` の `amazon` セクションのコメントを外す
2. 環境変数を AWS 用に変更
3. `config/environments/production.rb` を変更:
   ```ruby
   config.active_storage.service = :amazon
   ```

### データ移行

R2 から他サービスへのデータ移行:

```bash
# rclone を使用（推奨）
rclone copy cloudflare-r2:bucket-name aws-s3:bucket-name
```

---

## 13. 参考資料

### 公式ドキュメント

- **Cloudflare R2**: https://developers.cloudflare.com/r2/
- **R2 API**: https://developers.cloudflare.com/r2/api/s3/
- **Active Storage**: https://edgeguides.rubyonrails.org/active_storage_overview.html

### 料金計算ツール

- **R2 Pricing**: https://developers.cloudflare.com/r2/platform/pricing/

---

## 付録: よくある質問

### Q1: 本当に無料で使えますか？

A: はい。このプロジェクトの規模（月50-300MB）なら、10GB無料枠で数年間運用可能です。

### Q2: クレジットカード登録は必須ですか？

A: はい。無料枠超過時の課金用に必要ですが、通常の使用では請求されません。

### Q3: AWS S3 との違いは？

A: 主な違いは**エグレス（データ転送）料金が完全無料**という点です。S3互換APIなので、実装はほぼ同じです。

### Q4: 日本からのアクセス速度は？

A: Cloudflare の世界中のエッジネットワークを経由するため、十分高速です。

### Q5: バックアップは必要ですか？

A: R2 自体に冗長性がありますが、重要なデータは定期的にローカルにバックアップすることを推奨します。

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: 本番運用開始時
