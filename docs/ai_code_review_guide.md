# AIコードレビューガイド

**作成日**: 2025-10-13
**対象**: Phase 3以降の全PR
**ツール**: Claude Code

---

## 概要

Phase 3以降、全てのPRに対してClaude Codeによる自動コードレビューを標準プロセスとして実施します。
個人開発プロジェクトですが、コード品質とセキュリティ確保のため、体系的なレビューを導入します。

---

## レビュー実施手順

### 1. PR作成

通常のPR作成フローに従って実装を完了し、PRを作成します。

```bash
git push -u origin feature/p3-XX-feature-name
gh pr create --title "タイトル" --body "本文"
```

### 2. AIコードレビュー実行

Claude Codeに以下のように依頼します:

```
自分で実装した機能をコードレビューしてください
```

Claude Codeは以下のプロセスでレビューを実施:
1. `Task`ツールで`quality-engineer`サブエージェントを起動
2. 実装ファイルを全て読み込み
3. コード品質、セキュリティ、ベストプラクティスを分析
4. Critical/Minorに分類したレビュー結果を返却

### 3. レビュー結果をPRにコメント

```bash
gh pr review <PR番号> --comment -b "$(cat <<'EOF'
## AIコードレビュー結果

### Critical Issues
1. **問題の概要**
   - 詳細説明
   - 対応方法

### Minor Issues
1. 問題の概要
2. 問題の概要

### Good Points
- ✅ 良い点1
- ✅ 良い点2
EOF
)"
```

### 4. Criticalな問題を修正

**必須**: Criticalな問題は全て修正してください。

```bash
# 修正実施
# テスト実行
bundle exec rspec
bundle exec rubocop -A

# コミット
git add .
git commit -m "refactor: コードレビュー指摘事項の対応

- Critical問題1の修正
- Critical問題2の修正
- Minor問題1の修正

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push
```

### 5. Minorな問題を修正（推奨）

可能な限りMinorな問題も対応してください。

### 6. CI確認・マージ

全てのCIチェックが成功したらマージします。

```bash
gh pr merge <PR番号> --squash
```

---

## レビュー基準

### Critical（必須修正）

セキュリティやデータ整合性に関わる重大な問題。必ず修正してからマージしてください。

#### 1. セキュリティ脆弱性

- SQLインジェクション
- XSS（クロスサイトスクリプティング）
- CSRF対策漏れ
- 機密情報のログ出力
- 不適切な権限設定

**例**:
```ruby
# ❌ Bad: SQLインジェクション脆弱性
User.where("email = '#{params[:email]}'")

# ✅ Good: プレースホルダー使用
User.where(email: params[:email])
```

#### 2. 認可・認証の不備

- 認証チェック漏れ
- 認可チェック漏れ（他ユーザーのリソースアクセス）
- セッション管理の問題

**例**:
```ruby
# ❌ Bad: 認可チェックなし
def edit
  @cost_sheet = CostSheet.find(params[:id])
end

# ✅ Good: 自分のリソースのみ
def edit
  @cost_sheet = current_user.cost_sheets.find(params[:id])
end
```

#### 3. データ整合性の問題

- トランザクション漏れ
- 外部キー制約違反の可能性
- 不適切なカスケード削除
- バリデーション不足

**例**:
```ruby
# ❌ Bad: トランザクションなし
def transfer_points
  user1.update!(points: user1.points - amount)
  user2.update!(points: user2.points + amount)
end

# ✅ Good: トランザクション使用
def transfer_points
  ActiveRecord::Base.transaction do
    user1.update!(points: user1.points - amount)
    user2.update!(points: user2.points + amount)
  end
end
```

#### 4. 重大なバグ

- N+1クエリ問題（大量データで性能劣化）
- メモリリーク
- 無限ループの可能性
- 例外処理漏れ

### Minor（推奨修正）

コード品質や保守性に関する改善点。可能な限り対応してください。

#### 1. コード品質改善

- 非推奨APIの使用
- 複雑すぎるメソッド（Cyclomatic Complexity高）
- DRY原則違反（重複コード）
- マジックナンバー

**例**:
```ruby
# ❌ Bad: 非推奨ステータスコード
render :new, status: :unprocessable_entity

# ✅ Good: Rails 7.1+の推奨
render :new, status: :unprocessable_content
```

#### 2. ベストプラクティス適用

- 命名規則違反
- 不適切なスコープ
- 過度なネスト
- 長すぎるメソッド

**例**:
```ruby
# ❌ Bad: 長すぎるメソッド
def create
  @user = User.new(user_params)
  if @user.save
    # 50行以上のコード...
  end
end

# ✅ Good: メソッド分割
def create
  @user = User.new(user_params)
  if @user.save
    handle_successful_creation
  else
    handle_failed_creation
  end
end
```

#### 3. パフォーマンス最適化

- eager loadingの使用推奨
- 不要なクエリ削減
- インデックス追加推奨

**例**:
```ruby
# ❌ Bad: N+1クエリ
@users.each do |user|
  user.posts.each { |post| ... }
end

# ✅ Good: eager loading
@users.includes(:posts).each do |user|
  user.posts.each { |post| ... }
end
```

#### 4. 保守性向上

- コメント追加推奨
- テストカバレッジ向上
- ドキュメント整備

---

## レビュー項目チェックリスト

### セキュリティ

- [ ] 認証チェックが全てのアクションに実装されているか
- [ ] 認可チェックが適切に実装されているか（他ユーザーのリソースアクセス制御）
- [ ] Strong Parametersが適切に設定されているか
- [ ] SQLインジェクション対策されているか
- [ ] XSS対策されているか（ビューで適切なエスケープ）
- [ ] CSRF対策されているか（Rails標準機能）
- [ ] 機密情報がログに出力されていないか

### データ整合性

- [ ] 必要なバリデーションが全て実装されているか
- [ ] 外部キー制約が設定されているか
- [ ] トランザクションが適切に使用されているか
- [ ] カスケード削除が適切に設定されているか
- [ ] ユニーク制約が適切に設定されているか

### テスト

- [ ] モデルテストが充実しているか
- [ ] リクエストテストが充実しているか
- [ ] エッジケースがテストされているか
- [ ] 認可テストが実装されているか
- [ ] バリデーションテストが実装されているか

### コード品質

- [ ] DRY原則が守られているか
- [ ] SOLID原則が守られているか
- [ ] 命名規則が適切か
- [ ] メソッドが短く保たれているか（10行以内推奨）
- [ ] ネストが深すぎないか（3階層以内推奨）
- [ ] RuboCop違反がないか

### パフォーマンス

- [ ] N+1クエリが発生していないか
- [ ] 適切なインデックスが設定されているか
- [ ] 不要なクエリが実行されていないか
- [ ] eager loadingが適切に使用されているか

---

## 実例: PR #1のレビュー結果

### 実施内容

PR #1（コストシート管理機能）に対してAIコードレビューを実施しました。

### レビュー結果

#### Critical Issues

1. **認可テスト不足**
   - 他ユーザーのコストシートへのアクセス制御テストが未実装
   - edit, update, deleteアクションの認可テストが必要
   - **対応**: `spec/requests/cost_sheets_spec.rb`に3つの認可テストを追加

#### Minor Issues

1. **カテゴリバリデーション不足**
   - categoryカラムのバリデーションが未実装
   - **対応**: `validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }`追加

2. **非推奨ステータスコード使用**
   - `:unprocessable_entity`は非推奨（Rails 7.1+）
   - **対応**: `:unprocessable_content`に変更

#### Good Points

- ✅ テストカバレッジ充実（モデル15+、リクエスト18+）
- ✅ スコープ実装適切（by_name, recent, by_category）
- ✅ バリデーション基本完備（item_name, standard_price）
- ✅ Strong Parameters適切
- ✅ RuboCop違反なし

### 修正内容

```ruby
# spec/requests/cost_sheets_spec.rb に追加
describe '他のユーザーのリソースへのアクセス' do
  let(:other_user) { create(:user) }
  let(:other_cost_sheet) { create(:cost_sheet, user: other_user) }

  it '他のユーザーのコストシートを編集できない' do
    get edit_cost_sheet_path(other_cost_sheet)
    expect(response).to have_http_status(:not_found)
  end

  it '他のユーザーのコストシートを更新できない' do
    original_name = other_cost_sheet.item_name
    patch cost_sheet_path(other_cost_sheet), params: { cost_sheet: { item_name: 'hacked' } }
    expect(response).to have_http_status(:not_found)
    expect(other_cost_sheet.reload.item_name).to eq(original_name)
  end

  it '他のユーザーのコストシートを削除できない' do
    other_cost_sheet_id = other_cost_sheet.id
    delete cost_sheet_path(other_cost_sheet)
    expect(response).to have_http_status(:not_found)
    expect(CostSheet.exists?(other_cost_sheet_id)).to be true
  end
end

# app/models/cost_sheet.rb に追加
validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }

# app/controllers/cost_sheets_controller.rb 更新
render :new, status: :unprocessable_content   # was :unprocessable_entity
render :edit, status: :unprocessable_content  # was :unprocessable_entity
```

### 結果

- 全テスト成功: 37 examples, 0 failures
- RuboCop: 0違反
- CI: 全チェック成功 ✅

---

## よくある問題と対応方法

### 1. 認可漏れ

**問題**: 他ユーザーのリソースにアクセスできてしまう

**検出方法**:
```ruby
# コントローラーでグローバルスコープを使用している
@cost_sheet = CostSheet.find(params[:id])
```

**対応方法**:
```ruby
# current_userのスコープに限定
@cost_sheet = current_user.cost_sheets.find(params[:id])

# テスト追加
it '他のユーザーのリソースにアクセスできない' do
  get edit_resource_path(other_user_resource)
  expect(response).to have_http_status(:not_found)
end
```

### 2. バリデーション不足

**問題**: 不正なデータが保存されてしまう

**検出方法**: モデルのバリデーションを確認

**対応方法**:
```ruby
# モデルにバリデーション追加
validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }
validates :price, numericality: { greater_than_or_equal_to: 0 }

# テスト追加
it { is_expected.to validate_inclusion_of(:category).in_array(CATEGORIES.keys) }
```

### 3. N+1クエリ

**問題**: ループ内でクエリが大量発生

**検出方法**: Bullet gem使用または手動確認

**対応方法**:
```ruby
# Before
@users.each { |user| user.posts.count }

# After
@users = User.includes(:posts)
@users.each { |user| user.posts.count }
```

### 4. 非推奨API使用

**問題**: 将来のバージョンで動作しなくなる可能性

**検出方法**: レビューまたは警告メッセージ

**対応方法**:
```ruby
# Before (Rails 7.0以前)
render :new, status: :unprocessable_entity

# After (Rails 7.1+)
render :new, status: :unprocessable_content
```

---

## Tips

### 効率的なレビュー実施

1. **PR作成直後にレビュー**: 記憶が新しいうちに修正
2. **Criticalを優先**: まず重大な問題を全て修正
3. **Minorも対応**: コード品質向上のため可能な限り対応
4. **テスト追加**: レビュー指摘事項のテストを必ず追加
5. **パターン学習**: 同じ問題を繰り返さないよう学習

### レビュー結果の活用

- **チェックリスト化**: よく指摘される項目をチェックリストに追加
- **実装ガイド更新**: 繰り返し指摘される問題を実装ガイドに反映
- **テンプレート化**: よく使うテストパターンをテンプレート化

### 継続的改善

- **レビュー履歴**: 過去のレビュー結果を振り返る
- **傾向分析**: よく指摘される問題の傾向を分析
- **予防**: 実装前にチェックリストを確認

---

## 参考資料

### セキュリティ

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

### コード品質

- [Ruby Style Guide](https://rubystyle.guide/)
- [Rails Best Practices](https://rails-bestpractices.com/)

### テスト

- [RSpec Best Practices](https://rspec.rubystyle.guide/)
- [Better Specs](https://www.betterspecs.org/)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-13
**Status**: Active

このガイドに従って、全てのPRに対してAIコードレビューを実施してください！
