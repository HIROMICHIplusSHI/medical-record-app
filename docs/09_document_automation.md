# ドキュメント更新自動化ガイド

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0
**言語**: 日本語

---

## 1. はじめに

### 1.1 本ドキュメントの目的

本書は、プロジェクトドキュメントの更新を自動化・半自動化し、ドキュメントとコードの同期を維持するためのガイドです。

**自動化の範囲:**
- ✅ ドキュメント更新チェック（Pre-commit hook）
- ✅ 変更履歴の自動生成（CHANGELOG）
- ✅ ドキュメントバージョン管理
- ✅ ドキュメント一貫性チェック

### 1.2 目標

- ドキュメントの更新忘れを防止
- コードとドキュメントの乖離を最小化
- レビュー負荷の軽減
- ドキュメント品質の向上

---

## 2. Git Hooks によるドキュメント更新チェック

### 2.1 Pre-commit Hook セットアップ

**目的:** コミット前にドキュメント更新の必要性をチェック

#### 2.1.1 Overcommit Gem のインストール

```ruby
# Gemfile
group :development do
  gem 'overcommit', '~> 0.60'
end
```

```bash
bundle install
overcommit --install
```

#### 2.1.2 設定ファイル作成

```yaml
# .overcommit.yml
PreCommit:
  RuboCop:
    enabled: true
    on_warn: fail
    command: ['bundle', 'exec', 'rubocop']

  BundleCheck:
    enabled: true

  YamlSyntax:
    enabled: true

  # カスタムフック: ドキュメント更新チェック
  ExecuteCommand:
    enabled: true
    required_executable: 'bash'
    command: ['scripts/check_docs.sh']
    flags: []
    install_command: 'chmod +x scripts/check_docs.sh'

CommitMsg:
  TextWidth:
    enabled: true
    max_subject_width: 72
```

#### 2.1.3 ドキュメント更新チェックスクリプト

```bash
# scripts/check_docs.sh
#!/bin/bash

# ドキュメント更新チェックスクリプト

set -e

# 変更されたファイルを取得
changed_files=$(git diff --cached --name-only --diff-filter=ACM)

# モデル/コントローラー/ビューが変更された場合
if echo "$changed_files" | grep -qE "^app/(models|controllers|views)/"; then
  echo "⚠️  警告: モデル・コントローラー・ビューが変更されています"
  echo ""
  echo "以下のドキュメントの更新を確認してください:"
  echo "  - docs/07_detailed_design.md （詳細設計書）"
  echo "  - docs/08_screen_design.md （画面設計書）"
  echo ""
  echo "ドキュメント更新が完了している場合は、そのままコミットしてください。"
  echo ""

  # ドキュメントが同時に更新されているかチェック
  if echo "$changed_files" | grep -qE "^docs/"; then
    echo "✅ ドキュメントも更新されています"
  else
    echo "❌ ドキュメントが更新されていません"
    echo ""
    read -p "ドキュメント更新をスキップしてコミットしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "コミットを中断しました。ドキュメントを更新してから再度コミットしてください。"
      exit 1
    fi
  fi
fi

# マイグレーションファイルが変更された場合
if echo "$changed_files" | grep -qE "^db/migrate/"; then
  echo "⚠️  警告: マイグレーションファイルが変更されています"
  echo ""
  echo "以下のドキュメントの更新を確認してください:"
  echo "  - docs/02_data_model.md （データモデル設計）"
  echo "  - docs/07_detailed_design.md （詳細設計書）"
  echo ""
fi

# ルーティングが変更された場合
if echo "$changed_files" | grep -qE "^config/routes.rb"; then
  echo "⚠️  警告: ルーティングが変更されています"
  echo ""
  echo "以下のドキュメントの更新を確認してください:"
  echo "  - docs/07_detailed_design.md （詳細設計書）"
  echo "  - docs/08_screen_design.md （画面設計書）"
  echo ""
fi

echo "✅ ドキュメント更新チェック完了"
exit 0
```

```bash
chmod +x scripts/check_docs.sh
```

#### 2.1.4 使用方法

```bash
# 通常のコミット
git add .
git commit -m "Add Facility CRUD"

# フックが自動実行される
# ドキュメント更新が必要な場合は警告が表示される
```

**フックを一時的にスキップする場合:**

```bash
git commit -m "WIP: temporary work" --no-verify
```

---

## 3. CHANGELOG 自動生成

### 3.1 conventional-changelog のセットアップ

**目的:** コミットメッセージから CHANGELOG を自動生成

#### 3.1.1 パッケージインストール

```bash
# Node.js プロジェクトとして初期化（まだの場合）
npm init -y

# conventional-changelog-cli のインストール
npm install --save-dev conventional-changelog-cli
```

#### 3.1.2 package.json にスクリプト追加

```json
{
  "name": "medical-record-app",
  "version": "1.0.0",
  "scripts": {
    "changelog": "conventional-changelog -p angular -i CHANGELOG.md -s",
    "changelog:all": "conventional-changelog -p angular -i CHANGELOG.md -s -r 0"
  },
  "devDependencies": {
    "conventional-changelog-cli": "^4.1.0"
  }
}
```

#### 3.1.3 コミットメッセージ規約

**Angular Convention に従う:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**type の種類:**

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響しない変更（空白、フォーマット等）
- `refactor`: バグ修正でも機能追加でもないコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更

**例:**

```bash
git commit -m "feat(facility): add CRUD functionality for facilities

- Implement Facility model with validations
- Add FacilitiesController with all CRUD actions
- Create views for facility management
- Add comprehensive tests (Model, Request, System)

Closes #12"
```

```bash
git commit -m "fix(patient): correct age calculation for leap year

The age calculation was incorrect for patients born on Feb 29.
Fixed by properly handling leap years.

Fixes #23"
```

```bash
git commit -m "docs(readme): update Phase 1 completion status"
```

#### 3.1.4 CHANGELOG 生成

```bash
# 最新の変更のみを追加
npm run changelog

# すべての履歴から生成
npm run changelog:all
```

**生成される CHANGELOG.md 例:**

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-10-12

### Features

* **facility:** add CRUD functionality for facilities ([abc123](https://github.com/user/repo/commit/abc123))
* **patient:** add patient management with search ([def456](https://github.com/user/repo/commit/def456))
* **medical-record:** implement medical record with dynamic form ([ghi789](https://github.com/user/repo/commit/ghi789))

### Bug Fixes

* **patient:** correct age calculation for leap year ([jkl012](https://github.com/user/repo/commit/jkl012))
* **image-upload:** fix file size validation ([mno345](https://github.com/user/repo/commit/mno345))

### Documentation

* **readme:** update Phase 1 completion status ([pqr678](https://github.com/user/repo/commit/pqr678))
```

---

## 4. ドキュメントバージョン管理

### 4.1 ドキュメントヘッダー規約

**すべてのドキュメントに以下のヘッダーを付与:**

```markdown
# ドキュメント名

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0
**言語**: 日本語
**最終更新**: 2025-10-12
**変更履歴**:
- 1.0 (2025-10-12): 初版作成
- 1.1 (2025-10-15): Phase 1完了に伴う更新
```

### 4.2 バージョン番号規則

**セマンティックバージョニング:**

```
MAJOR.MINOR.PATCH

- MAJOR: 互換性のない大きな変更（Phase完了時）
- MINOR: 後方互換性のある機能追加（新機能追加時）
- PATCH: 後方互換性のあるバグ修正（誤字修正等）
```

**例:**
- `1.0`: Phase 1 完了時
- `1.1`: Phase 1 に機能追加
- `1.0.1`: Phase 1 ドキュメント誤字修正
- `2.0`: Phase 2 完了時

### 4.3 ドキュメント更新スクリプト

```bash
# scripts/update_doc_version.sh
#!/bin/bash

# ドキュメントバージョン更新スクリプト

DOC_FILE=$1
VERSION=$2
CHANGE_NOTE=$3

if [ -z "$DOC_FILE" ] || [ -z "$VERSION" ] || [ -z "$CHANGE_NOTE" ]; then
  echo "Usage: ./scripts/update_doc_version.sh <doc_file> <version> <change_note>"
  echo "Example: ./scripts/update_doc_version.sh docs/07_detailed_design.md 1.1 'Add Invoice model'"
  exit 1
fi

# 最終更新日を今日の日付に
TODAY=$(date +%Y-%m-%d)

# バージョン行を更新
sed -i.bak "s/\*\*バージョン\*\*:.*/\*\*バージョン\*\*: $VERSION/" "$DOC_FILE"

# 最終更新日を更新
sed -i.bak "s/\*\*最終更新\*\*:.*/\*\*最終更新\*\*: $TODAY/" "$DOC_FILE"

# 変更履歴に追加（ヘッダー部分を探して挿入）
# この部分は実際のドキュメント構造に合わせて調整が必要

echo "✅ $DOC_FILE を バージョン $VERSION に更新しました"
echo "変更内容: $CHANGE_NOTE"

rm -f "${DOC_FILE}.bak"
```

```bash
chmod +x scripts/update_doc_version.sh
```

**使用例:**

```bash
./scripts/update_doc_version.sh docs/07_detailed_design.md 1.1 "Add Invoice model and InvoiceGenerationService"
```

---

## 5. ドキュメント一貫性チェック

### 5.1 Markdownlint セットアップ

**目的:** Markdown ファイルの品質を保証

#### 5.1.1 インストール

```bash
npm install --save-dev markdownlint-cli
```

#### 5.1.2 設定ファイル作成

```json
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD033": false,
  "MD041": false
}
```

保存先: `.markdownlint.json`

#### 5.1.3 package.json にスクリプト追加

```json
{
  "scripts": {
    "lint:md": "markdownlint 'docs/**/*.md' 'README.md'",
    "lint:md:fix": "markdownlint 'docs/**/*.md' 'README.md' --fix"
  }
}
```

#### 5.1.4 実行

```bash
# チェックのみ
npm run lint:md

# 自動修正
npm run lint:md:fix
```

### 5.2 ドキュメント構造チェックスクリプト

```bash
# scripts/check_doc_structure.sh
#!/bin/bash

# ドキュメント構造チェックスクリプト

set -e

DOCS_DIR="docs"

echo "📋 ドキュメント構造チェック開始..."
echo ""

# 必須ドキュメントの存在確認
REQUIRED_DOCS=(
  "01_requirements.md"
  "02_data_model.md"
  "03_technical_stack.md"
  "04_development_plan.md"
  "05_testing_strategy.md"
  "06_cloudflare_r2_setup.md"
  "07_detailed_design.md"
  "08_screen_design.md"
  "09_phase1_implementation_guide.md"
)

MISSING_DOCS=()

for doc in "${REQUIRED_DOCS[@]}"; do
  if [ ! -f "$DOCS_DIR/$doc" ]; then
    MISSING_DOCS+=("$doc")
  fi
done

if [ ${#MISSING_DOCS[@]} -gt 0 ]; then
  echo "❌ 以下の必須ドキュメントが見つかりません:"
  for doc in "${MISSING_DOCS[@]}"; do
    echo "  - $doc"
  done
  exit 1
else
  echo "✅ すべての必須ドキュメントが存在します"
fi

# ドキュメントヘッダーチェック
echo ""
echo "🔍 ドキュメントヘッダーチェック..."

for doc_file in "$DOCS_DIR"/*.md; do
  # プロジェクト名が記載されているか
  if ! grep -q "**プロジェクト名**:" "$doc_file"; then
    echo "⚠️  警告: $doc_file にプロジェクト名がありません"
  fi

  # バージョンが記載されているか
  if ! grep -q "**バージョン**:" "$doc_file"; then
    echo "⚠️  警告: $doc_file にバージョン情報がありません"
  fi
done

echo ""
echo "✅ ドキュメント構造チェック完了"
```

```bash
chmod +x scripts/check_doc_structure.sh
```

**実行:**

```bash
./scripts/check_doc_structure.sh
```

---

## 6. GitHub Actions による CI/CD 統合

### 6.1 ワークフロー作成

```yaml
# .github/workflows/documentation.yml
name: Documentation Check

on:
  pull_request:
    paths:
      - 'docs/**'
      - 'README.md'
  push:
    branches:
      - main
    paths:
      - 'docs/**'
      - 'README.md'

jobs:
  check-docs:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run Markdownlint
        run: npm run lint:md

      - name: Check document structure
        run: ./scripts/check_doc_structure.sh

      - name: Check for broken links
        uses: gaurav-nelson/github-action-markdown-link-check@v1
        with:
          use-quiet-mode: 'yes'
          config-file: '.markdown-link-check.json'
```

### 6.2 リンクチェック設定

```json
{
  "ignorePatterns": [
    {
      "pattern": "^http://localhost"
    }
  ],
  "httpHeaders": [
    {
      "urls": ["https://github.com"],
      "headers": {
        "Accept-Encoding": "zstd, br, gzip, deflate"
      }
    }
  ],
  "timeout": "20s",
  "retryOn429": true,
  "retryCount": 3,
  "fallbackRetryDelay": "30s"
}
```

保存先: `.markdown-link-check.json`

---

## 7. ドキュメント更新ワークフロー

### 7.1 通常の更新フロー

```bash
# 1. 機能ブランチ作成
git checkout -b feature/add-invoice-model

# 2. コード実装
# app/models/invoice.rb などを編集

# 3. ドキュメント更新
# docs/07_detailed_design.md を更新
# ドキュメントバージョンを更新
./scripts/update_doc_version.sh docs/07_detailed_design.md 1.1 "Add Invoice model"

# 4. コミット（Conventional Commits形式）
git add .
git commit -m "feat(invoice): add Invoice model and generation service

- Implement Invoice model with auto-numbering
- Add InvoiceGenerationService
- Update detailed design document to v1.1

Refs #45"

# 5. テスト実行
bundle exec rspec

# 6. ドキュメントチェック
npm run lint:md
./scripts/check_doc_structure.sh

# 7. プッシュ
git push origin feature/add-invoice-model

# 8. Pull Request作成
```

### 7.2 Phase完了時のフロー

```bash
# 1. Phase 1完了時
git checkout main
git pull origin main

# 2. CHANGELOGを生成
npm run changelog

# 3. READMEを更新
# - 開発状況セクションを更新
# - Phase 1を完了にチェック

# 4. すべてのドキュメントバージョンをメジャーアップ
./scripts/update_doc_version.sh docs/07_detailed_design.md 2.0 "Phase 1 completed"
./scripts/update_doc_version.sh docs/08_screen_design.md 2.0 "Phase 1 completed"
./scripts/update_doc_version.sh docs/09_phase1_implementation_guide.md 1.0 "Phase 1 guide finalized"

# 5. コミット
git add .
git commit -m "chore(release): complete Phase 1 MVP

Phase 1 MVP implementation completed including:
- Facility management
- Patient management with search
- Cost sheet management
- Medical record management with dynamic forms
- Image upload functionality
- Tag system
- Test coverage: 85%

BREAKING CHANGE: Initial MVP release"

# 6. タグ作成
git tag -a v1.0.0 -m "Phase 1 MVP Release"

# 7. プッシュ
git push origin main --tags

# 8. GitHub Release作成
# GitHub UIでリリースノートを作成
```

---

## 8. ドキュメントテンプレート

### 8.1 新規ドキュメント作成時のテンプレート

```markdown
# [ドキュメント名]

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: YYYY-MM-DD
**バージョン**: 1.0
**言語**: 日本語
**最終更新**: YYYY-MM-DD
**変更履歴**:
- 1.0 (YYYY-MM-DD): 初版作成

---

## 1. はじめに

### 1.1 本ドキュメントの目的

[ドキュメントの目的を記述]

### 1.2 対象読者

- 開発者（自分自身）
- [その他の対象読者]

---

## 2. [セクション名]

[内容]

---

**Document Version**: 1.0
**Last Updated**: YYYY-MM-DD
**Next Review**: [レビュー予定日]
```

---

## 9. ツール一覧

### 9.1 インストール済みツール

| ツール | 用途 | コマンド |
|--------|------|----------|
| Overcommit | Git Hooks管理 | `overcommit --run` |
| conventional-changelog-cli | CHANGELOG生成 | `npm run changelog` |
| markdownlint-cli | Markdown品質チェック | `npm run lint:md` |

### 9.2 カスタムスクリプト

| スクリプト | 用途 | 場所 |
|-----------|------|------|
| check_docs.sh | ドキュメント更新チェック | scripts/check_docs.sh |
| update_doc_version.sh | ドキュメントバージョン更新 | scripts/update_doc_version.sh |
| check_doc_structure.sh | ドキュメント構造チェック | scripts/check_doc_structure.sh |

---

## 10. トラブルシューティング

### 10.1 Overcommit が動作しない

**問題:** Git Hookが実行されない

**解決策:**

```bash
# Overcommitを再インストール
overcommit --uninstall
overcommit --install

# フックに実行権限を付与
chmod +x .git/hooks/pre-commit
```

### 10.2 CHANGELOG生成時にエラー

**問題:** `conventional-changelog: command not found`

**解決策:**

```bash
# Node.js依存関係を再インストール
npm install

# または グローバルインストール
npm install -g conventional-changelog-cli
```

### 10.3 Markdownlintエラーが多い

**問題:** Markdownlintで多数の警告

**解決策:**

```bash
# 自動修正
npm run lint:md:fix

# 特定のルールを無効化（.markdownlint.json）
{
  "MD013": false  // 行の長さ制限を無効化
}
```

---

## 11. ベストプラクティス

### 11.1 コミットメッセージ

**良い例:**
```
feat(facility): add revenue calculation method

Implement total_revenue method with date range filtering.
Add specs for edge cases including empty records.

Closes #12
```

**悪い例:**
```
update facility
```

### 11.2 ドキュメント更新タイミング

- ✅ **同時更新**: コード変更とドキュメント更新を同じコミットで行う
- ✅ **小まめな更新**: 大きな変更前に小まめにコミット
- ❌ **後回し**: 実装完了後にまとめて更新（乖離が発生）

### 11.3 ドキュメントレビュー

**定期レビュー:**
- Phase完了時: 全ドキュメントレビュー
- 週次: 更新されたドキュメントのみレビュー

**レビュー観点:**
- コードとの一致性
- 誤字脱字
- バージョン情報の正確性
- リンク切れ

---

## 12. まとめ

### 12.1 自動化されること

- ✅ ドキュメント更新チェック（Pre-commit）
- ✅ CHANGELOG自動生成
- ✅ Markdown品質チェック
- ✅ ドキュメント構造チェック
- ✅ リンク切れチェック（CI/CD）

### 12.2 手動で行うこと

- 📝 ドキュメント内容の更新
- 📝 ドキュメントバージョンの更新
- 📝 変更履歴の記述
- 📝 コミットメッセージの作成

### 12.3 導入効果

**Before（自動化なし）:**
- ドキュメント更新を忘れる
- コードとドキュメントが乖離
- レビューで指摘される

**After（自動化あり）:**
- Pre-commitで更新を促される
- CHANGELOGが自動生成される
- CI/CDでドキュメント品質を保証

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: Phase 1実装開始時
