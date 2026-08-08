# Render デプロイ手順

このリポジトリは `render.yaml`（Blueprint）で Web サービスと PostgreSQL を一括作成できる。
旧デプロイ先（DB ごと削除済み）を置き換えて、ゼロから作り直す前提の手順。

## 前提

- Render アカウント
- `config/master.key` の中身（このリポジトリのローカルに存在。git には含まれない）
- （画像アップロードを使う場合のみ）Cloudflare R2 のキー4種

## 手順

### 1. Blueprint でサービスを作成

1. Render Dashboard → **New → Blueprint**
2. このリポジトリ（`medical-record-app`）を選択
3. `render.yaml` が検出される → **Apply**
4. Web サービス `medical-record-app` と DB `medical-record-db` が作成される

### 2. シークレットを入力

`render.yaml` で `sync: false` にした値は Render 側で手入力する。

| 環境変数 | 値 | 必須 |
|---|---|---|
| `RAILS_MASTER_KEY` | `config/master.key` の中身をそのまま貼る | **必須** |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 のアクセスキー | 任意（画像用） |
| `R2_SECRET_ACCESS_KEY` | R2 のシークレット | 任意（画像用） |
| `R2_ENDPOINT` | R2 のエンドポイント URL | 任意（画像用） |
| `R2_BUCKET_NAME` | R2 のバケット名 | 任意（画像用） |

> `RAILS_MASTER_KEY` が credentials を解錠し、Active Record Encryption のキーも
> そこから読み込まれる。暗号化キーを個別の環境変数で入れる必要はない。
> R2 未設定でもアプリは起動する（画像アップロードだけが無効になる）。

`master.key` の中身を確認するコマンド（ローカルで実行）:

```bash
cat config/master.key
```

### 3. デプロイ

- Apply 後、自動でビルド → デプロイが走る
- ビルド（`bin/render-build.sh`）で `assets:precompile` → `db:migrate` → `db:seed` を実行
- `db:seed` は冪等（`find_or_create_by!`）なので再デプロイしても重複しない
- ヘルスチェックは `/up`（200 が返れば起動成功）

### 4. 動作確認

デプロイ完了後、発行された URL にアクセスしてデモアカウントでログイン:

| 用途 | メール | パスワード |
|---|---|---|
| 一般ユーザー | `demo@example.com` | `password123` |
| 管理者 | `admin@example.com` | `password123` |

問題なければ、発行された URL を `README.md` の「デモ環境」に記載する。

## トラブルシューティング

- **ビルド失敗（assets）**: `RAILS_MASTER_KEY` が正しく設定されているか確認
- **DB 接続エラー**: `DATABASE_URL` が DB から注入されているか（Blueprint なら自動）
- **無料 PostgreSQL の期限切れ**: Render の無料 DB は有効期限がある。長期公開するなら
  有料プランへ変更するか、期限切れ時に新しい DB を作り直して `DATABASE_URL` を差し替える
- **初回アクセスが遅い**: 無料プランはスリープする。初回リクエストで起動に数十秒かかる
