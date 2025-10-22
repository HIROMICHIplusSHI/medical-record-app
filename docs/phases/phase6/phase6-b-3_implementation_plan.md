# Phase 6-B-3: お問い合わせ機能 UI/UX改善 + 品質向上

**開始日**: 2025-10-22
**前提条件**: Phase 6-B-2完了（基本機能実装済み）
**ブランチ**: feature/phase6-b-3

---

## 📋 概要

Phase 6-B-2で実装した基本機能に対して、エージェントレビューで指摘されたMedium優先度の改善とUI/UX改善を実施します。

---

## 🎯 実装目標

### 1. Medium優先度の改善（セキュリティ・品質向上）

#### M-1: ステータスフィルタのバリデーション強化
**現状**: 不正なステータス値が送信された場合、例外が発生する
**目標**: 無効な値を送信されても安全に処理する

#### M-2: エラーメッセージのサニタイズ
**現状**: 例外メッセージがそのまま表示され、内部情報が漏洩する可能性
**目標**: ユーザーフレンドリーなメッセージを表示し、詳細はログに記録

#### M-3: status_i18nメソッドのテスト追加
**現状**: status_i18nメソッドがテストされていない
**目標**: 3つの状態（open, in_progress, closed）の日本語表記をテスト

### 2. UI/UX改善

#### U-1: メッセージの視覚的区別強化
**現状**: 管理者メッセージは背景色が異なるが、さらに視認性を向上させたい
**目標**:
- ユーザーメッセージと管理者メッセージの視覚的区別を強化
- アバター表示を追加（ユーザー/管理者アイコン）

#### U-2: メニューバー通知機能
**目標**:
- ヘッダーに未読お問い合わせ数を表示
- 管理者：未対応（open）のお問い合わせ数
- ユーザー：管理者からの返信があった未読メッセージ数

---

## 📝 実装タスク

### Task 1: ステータスフィルタのバリデーション強化

#### 実装内容
```ruby
# app/controllers/admin/inquiries_controller.rb
def index
  @inquiries = Inquiry.recent.page(params[:page])

  # 有効なステータス値のみ受け付ける
  if params[:status].present? && Inquiry.statuses.key?(params[:status])
    @inquiries = @inquiries.by_status(params[:status])
  end
end
```

#### テスト追加
```ruby
# spec/requests/admin/inquiries_spec.rb
context 'ステータスフィルタ' do
  it '無効なステータス値の場合、すべてのお問い合わせが表示される' do
    create(:inquiry, status: :open)
    create(:inquiry, :in_progress)

    get admin_inquiries_path, params: { status: 'invalid_status' }

    expect(response).to have_http_status(:success)
    # 全件表示される（フィルタリングされない）
  end
end
```

---

### Task 2: エラーメッセージのサニタイズ

#### 実装内容
```ruby
# app/controllers/inquiries_controller.rb
def create
  @inquiry = current_user.inquiries.build(inquiry_params.except(:body))

  ActiveRecord::Base.transaction do
    if @inquiry.save
      @inquiry.inquiry_messages.create!(
        user: current_user,
        body: inquiry_params[:body]
      )
      redirect_to @inquiry, notice: 'お問い合わせを送信しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end
rescue ActiveRecord::RecordInvalid => e
  # ユーザーには一般的なメッセージを表示
  @inquiry.errors.add(:base, 'お問い合わせの送信に失敗しました。入力内容をご確認ください。')

  # 詳細はログに記録
  Rails.logger.error("Inquiry creation failed for user #{current_user.id}: #{e.message}")

  render :new, status: :unprocessable_entity
end
```

#### テスト追加
```ruby
# spec/requests/inquiries_spec.rb
context 'トランザクション失敗時' do
  it 'ユーザーフレンドリーなエラーメッセージが表示される' do
    allow_any_instance_of(InquiryMessage).to receive(:save!).and_raise(
      ActiveRecord::RecordInvalid.new
    )

    post inquiries_path, params: valid_attributes

    expect(response.body).to include('お問い合わせの送信に失敗しました')
    expect(response.body).not_to include('ActiveRecord')
    expect(response.body).not_to include('RecordInvalid')
  end
end
```

---

### Task 3: status_i18nメソッドのテスト追加

#### テスト追加
```ruby
# spec/models/inquiry_spec.rb
describe '#status_i18n' do
  it 'openの場合、"未対応"を返す' do
    inquiry = build(:inquiry, status: :open)
    expect(inquiry.status_i18n).to eq('未対応')
  end

  it 'in_progressの場合、"対応中"を返す' do
    inquiry = build(:inquiry, status: :in_progress)
    expect(inquiry.status_i18n).to eq('対応中')
  end

  it 'closedの場合、"対応完了"を返す' do
    inquiry = build(:inquiry, status: :closed)
    expect(inquiry.status_i18n).to eq('対応完了')
  end
end
```

---

### Task 4: メッセージの視覚的区別強化

#### 実装内容

**ビュー改善（ユーザー側）**:
```erb
<!-- app/views/inquiries/show.html.erb -->
<% @inquiry_messages.each do |message| %>
  <div class="card <%= message.user.admin? ? 'bg-accent/10 border-accent' : 'bg-base-200' %> shadow mb-4">
    <div class="card-body">
      <div class="flex items-start gap-3">
        <!-- アバター -->
        <div class="avatar placeholder">
          <div class="<%= message.user.admin? ? 'bg-accent text-accent-content' : 'bg-neutral text-neutral-content' %> rounded-full w-10">
            <span class="text-xl">
              <%= message.user.admin? ? '🛡️' : '👤' %>
            </span>
          </div>
        </div>

        <div class="flex-1">
          <div class="flex justify-between items-center mb-2">
            <div class="flex items-center gap-2">
              <span class="font-semibold"><%= message.user.name %></span>
              <% if message.user.admin? %>
                <span class="badge badge-sm badge-accent">管理者</span>
              <% end %>
            </div>
            <span class="text-sm text-base-content/70">
              <%= l(message.created_at, format: :short) %>
            </span>
          </div>
          <div class="whitespace-pre-wrap"><%= message.body %></div>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

**ビュー改善（管理者側）**:
```erb
<!-- app/views/admin/inquiries/show.html.erb -->
<!-- 同様のアバター表示を追加 -->
```

#### System Specテスト
```ruby
# spec/system/inquiry_workflows_spec.rb
describe 'メッセージ表示' do
  it 'アバターが表示される', js: true do
    inquiry = create(:inquiry, user: user)
    create(:inquiry_message, inquiry: inquiry, user: user, body: 'ユーザーメッセージ')

    visit inquiry_path(inquiry)

    # ユーザーアバターアイコン
    expect(page).to have_content('👤')
  end
end

# spec/system/admin/inquiries_spec.rb
describe '管理者メッセージ表示' do
  it '管理者アバターが表示される', js: true do
    inquiry = create(:inquiry, user: normal_user)
    create(:inquiry_message, inquiry: inquiry, user: admin_user, body: '管理者返信')

    visit admin_inquiry_path(inquiry)

    # 管理者アバターアイコン
    expect(page).to have_content('🛡️')
    expect(page).to have_selector('.badge-accent', text: '管理者')
  end
end
```

---

### Task 5: メニューバー通知機能

#### データモデル拡張（オプション）

**選択肢1**: シンプルな実装（カウントのみ）
- 管理者：`Inquiry.where(status: :open).count`
- ユーザー：現状では未実装（Phase 6-B-4で実装予定）

**選択肢2**: 既読管理テーブル追加（Phase 6-B-4で検討）
- `InquiryRead`モデル（user_id, inquiry_id, last_read_at）

#### 実装内容（シンプル版）

**ヘルパーメソッド追加**:
```ruby
# app/helpers/application_helper.rb
def unread_inquiry_count(user)
  return 0 unless user

  if user.admin?
    # 管理者：未対応のお問い合わせ数
    Inquiry.where(status: :open).count
  else
    # ユーザー：現状では0（Phase 6-B-4で実装予定）
    0
  end
end
```

**ヘッダー更新**:
```erb
<!-- app/views/shared/_header.html.erb -->
<nav class="hidden md:flex items-center space-x-1" role="navigation">
  <% if current_user.admin? %>
    <%= link_to_nav_item('お問い合わせ', admin_inquiries_path) do %>
      お問い合わせ
      <% if (count = unread_inquiry_count(current_user)) > 0 %>
        <span class="badge badge-sm badge-primary ml-1"><%= count %></span>
      <% end %>
    <% end %>
  <% else %>
    <%= link_to_nav_item('お問い合わせ', inquiries_path) %>
  <% end %>
</nav>
```

**ヘルパーメソッド修正（バッジ対応）**:
```ruby
# app/helpers/application_helper.rb
def link_to_nav_item(text, path, &block)
  is_active = current_page?(path)
  classes = "px-3 py-2 rounded-md text-sm font-medium transition-colors #{
    is_active ? 'bg-blue-700' : 'hover:bg-blue-700'
  }"

  if block_given?
    link_to path, class: classes do
      capture(&block)
    end
  else
    link_to text, path, class: classes
  end
end
```

#### System Specテスト
```ruby
# spec/system/admin/inquiries_spec.rb
describe 'ヘッダー通知' do
  context '未対応のお問い合わせがある場合' do
    let!(:open_inquiries) { create_list(:inquiry, 3, status: :open) }

    it 'ヘッダーに未対応数が表示される', js: true do
      visit admin_root_path

      within('nav.hidden.md\\:flex') do
        expect(page).to have_selector('.badge-primary', text: '3')
      end
    end
  end

  context '未対応のお問い合わせがない場合' do
    it 'バッジが表示されない', js: true do
      visit admin_root_path

      within('nav.hidden.md\\:flex') do
        expect(page).not_to have_selector('.badge-primary')
      end
    end
  end
end
```

---

## ✅ テスト戦略

### 追加テスト

| テストタイプ | 追加件数 | 内容 |
|-------------|---------|------|
| Model Spec | +3 | status_i18nメソッド（3状態） |
| Request Spec | +2 | 無効ステータスフィルタ、エラーメッセージサニタイズ |
| System Spec | +4 | アバター表示、ヘッダー通知（管理者側） |
| Helper Spec | +3 | unread_inquiry_countヘルパー |
| **合計** | **+12** | **106 examples目標** |

---

## 📊 期待される成果

### 品質スコア改善

| 項目 | Phase 6-B-2 | Phase 6-B-3（目標） | 改善 |
|------|-------------|-------------------|------|
| Security | 82/100 | 90/100 | +8 |
| Quality | 92/100 | 95/100 | +3 |
| Architecture | 97.5/100 | 97.5/100 | - |
| **総合** | **90.5/100** | **94/100** | **+3.5** |

### セキュリティ改善
- ✅ M-1: 不正パラメータへの耐性向上
- ✅ M-2: 情報漏洩リスクの低減
- ✅ エラーハンドリングの改善

### UX改善
- ✅ メッセージの視認性向上（アバター表示）
- ✅ 管理者の業務効率化（未対応数の可視化）
- ✅ 視覚的フィードバックの強化

---

## 🚀 実装手順

### Step 1: Medium優先度の改善（TDD）
1. Task 1: ステータスフィルタのバリデーション強化
2. Task 2: エラーメッセージのサニタイズ
3. Task 3: status_i18nメソッドのテスト追加

### Step 2: UI/UX改善
4. Task 4: メッセージの視覚的区別強化
5. Task 5: メニューバー通知機能

### Step 3: テスト・レビュー
6. 全テスト実行（目標: 106 examples, 0 failures）
7. RuboCop実行
8. エージェントレビュー

### Step 4: ドキュメント・マージ
9. 完了報告作成
10. PRマージ

---

## 📝 次フェーズへの引継ぎ事項

### Phase 6-B-4で実装予定
- ユーザー側の未読管理機能
- InquiryReadモデルの追加
- リアルタイム通知（ActionCable）
- メール通知（ActionMailer）

---

## 📅 スケジュール

| タスク | 所要時間（見積） |
|--------|----------------|
| Task 1: ステータスフィルタ | 20分 |
| Task 2: エラーメッセージ | 20分 |
| Task 3: status_i18nテスト | 10分 |
| Task 4: 視覚的区別強化 | 40分 |
| Task 5: 通知機能 | 40分 |
| テスト・レビュー | 30分 |
| ドキュメント | 20分 |
| **合計** | **約3時間** |

---

**作成日**: 2025-10-22
**作成者**: Claude Code
