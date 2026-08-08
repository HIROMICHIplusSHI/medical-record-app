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
| `RAILS_MASTER_KEY` | `config/master.key` の中身 | **必須** |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | `db:encryption:init` の出力 | **必須** |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | 同上 | **必須** |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | 同上 | **必須** |
| `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_ENDPOINT` / `R2_BUCKET_NAME` | Cloudflare R2 の設定 | 任意（画像用） |

> **注意**: production が使う `config/credentials.yml.enc` には `secret_key_base` しか入っていない
> （Active Record Encryption のキーは development / test 用の credentials 側にのみ存在する）。
> そのため本番では暗号化キー3種を**環境変数で渡す必要がある**。未設定のままだとビルド中の
> `db:seed`（暗号化属性を持つ Patient を作成）で失敗する。
>
> `config/application.rb` は環境変数を優先して読むため、環境変数を設定すれば credentials 側は参照されない。
> R2 未設定でもアプリは起動する（画像アップロードだけが無効になる）。

値を取得するコマンド（ローカルで実行し、出力をコピーして貼り付ける）:

```bash
cat config/master.key
```

```bash
bin/rails db:encryption:init
```

`db:encryption:init` は `active_record_encryption:` 配下に3つのキーを出力する。
その値をそれぞれ対応する環境変数に設定する（YAML のキー名部分は貼らず、値だけを貼る）。

> 貼り付け時は**前後の空白・改行が混入しないよう**に注意。値の長さが不正だと
> `ArgumentError: key must be 16 bytes` 等で起動に失敗する。

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

- **`message_encryptor.rb` の `key=` で ArgumentError**: `RAILS_MASTER_KEY` が未設定・空・
  前後に空白/改行が混入している。Render の Environment で値を再確認する
  （`config/application.rb` が起動時に credentials を復号するため、ビルドの早い段階で落ちる）
- **`db:seed` で暗号化関連のエラー**: `ACTIVE_RECORD_ENCRYPTION_*` の3種が未設定。
  `bin/rails db:encryption:init` で生成して設定する
- **ビルド失敗（assets）**: `RAILS_MASTER_KEY` が正しく設定されているか確認
- **DB 接続エラー**: `DATABASE_URL` が DB から注入されているか（Blueprint なら自動）
- **無料 PostgreSQL の期限切れ**: Render の無料 DB は有効期限がある。長期公開するなら
  有料プランへ変更するか、期限切れ時に新しい DB を作り直して `DATABASE_URL` を差し替える
- **初回アクセスが遅い**: 無料プランはスリープする。初回リクエストで起動に数十秒かかる
