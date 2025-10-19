# Phase 5-C-5: 同意書テンプレートスナップショット化・看護師確認フロー

**作成日**: 2025-10-19
**ブランチ**: `feature/p5c5-consent-snapshot`
**PR**: （未作成）

---

## 📋 実装内容サマリー

Phase 5-C-4で残った3つの課題を解決します：

1. **同意書テンプレート内容のスナップショット化** 🔴 **最優先・法的証拠保全**
2. **署名漏れ時のバリデーション改善** 🟡
3. **看護師確認フロー追加** 🟡

---

## 🎯 タスク1: 同意書テンプレートスナップショット化

### 背景・目的

**現状の問題**:
- 同意書作成後にテンプレートを編集すると、過去の同意書の内容も変わってしまう
- 法的に書類改竄のリスクがある（証拠保全の原則違反）
- 訴訟・監査時に「その時点での同意内容」が証明できない

**現在のスナップショット対応済み**:
- ✅ 施設情報（facility_name, facility_address, facility_phone）
- ✅ 施術者名（practitioner_name）

**未対応（参照のみ）**:
- ❌ テンプレートタイトル（consent_form_template.title）
- ❌ 同意項目の内容（consent_form_item.content）

### 実装手順

#### Step 1: マイグレーション作成

```bash
rails g migration AddTemplateSnapshotToPatientConsents template_title:string
rails g migration AddItemContentToConsentItemResponses item_content:text
```

**追加カラム**:
- `patient_consents.template_title` (string): テンプレートタイトルのスナップショット
- `consent_item_responses.item_content` (text): 同意項目内容のスナップショット

#### Step 2: モデル変更

**app/models/patient_consent.rb**:
```ruby
# before_create コールバックでスナップショット保存
before_create :snapshot_template_title

private

def snapshot_template_title
  self.template_title = consent_form_template.title if consent_form_template.present?
end
```

**app/models/consent_item_response.rb**:
```ruby
# before_create コールバックでスナップショット保存
before_create :snapshot_item_content

private

def snapshot_item_content
  self.item_content = consent_form_item.content if consent_form_item.present?
end
```

#### Step 3: コントローラー変更

**app/controllers/patient_consents_controller.rb**:
- `build_patient_consent` メソッド内で consent_item_responses を作成する際、スナップショットが自動保存されることを確認

#### Step 4: ビュー変更

**app/views/patient_consents/show.html.erb**:
```erb
<!-- Before: 関連データから取得 -->
<%= @patient_consent.consent_form_template.title %>

<!-- After: スナップショット値を直接表示 -->
<%= @patient_consent.template_title %>
```

```erb
<!-- Before: 関連データから取得 -->
<%= response.consent_form_item.content %>

<!-- After: スナップショット値を直接表示 -->
<%= response.item_content %>
```

**app/views/patient_consents/index.html.erb**:
```erb
<!-- Before -->
<%= consent.consent_form_template.title %>

<!-- After -->
<%= consent.template_title %>
```

**app/services/patient_consent_pdf_generator.rb**:
```ruby
# Before
@pdf.text @patient_consent.consent_form_template.title

# After
@pdf.text @patient_consent.template_title
```

```ruby
# Before
@patient_consent.consent_item_responses.each do |response|
  checkbox = response.checked ? '[✓]' : '[ ]'
  @pdf.text "#{checkbox} #{response.consent_form_item.content}"
end

# After
@patient_consent.consent_item_responses.each do |response|
  checkbox = response.checked ? '[✓]' : '[ ]'
  @pdf.text "#{checkbox} #{response.item_content}"
end
```

#### Step 5: テスト更新

**spec/models/patient_consent_spec.rb**:
```ruby
describe 'コールバック' do
  describe '#snapshot_template_title' do
    it '作成時にテンプレートタイトルをスナップショットする' do
      template = create(:consent_form_template, title: 'オリジナルタイトル')
      consent = create(:patient_consent, consent_form_template: template)

      expect(consent.template_title).to eq('オリジナルタイトル')

      # テンプレート変更後も同意書のスナップショットは変わらない
      template.update(title: '変更後タイトル')
      consent.reload

      expect(consent.template_title).to eq('オリジナルタイトル')
    end
  end
end
```

**spec/models/consent_item_response_spec.rb**:
```ruby
describe 'コールバック' do
  describe '#snapshot_item_content' do
    it '作成時に同意項目内容をスナップショットする' do
      item = create(:consent_form_item, content: 'オリジナル内容')
      response = create(:consent_item_response, consent_form_item: item)

      expect(response.item_content).to eq('オリジナル内容')

      # 項目変更後もレスポンスのスナップショットは変わらない
      item.update(content: '変更後内容')
      response.reload

      expect(response.item_content).to eq('オリジナル内容')
    end
  end
end
```

**spec/services/patient_consent_pdf_generator_spec.rb**:
```ruby
# スナップショット値を使ったPDF生成のテスト
it 'スナップショットされたテンプレートタイトルを表示する' do
  expect(pdf_text).to include(patient_consent.template_title)
end

it 'スナップショットされた同意項目内容を表示する' do
  patient_consent.consent_item_responses.each do |response|
    expect(pdf_text).to include(response.item_content)
  end
end
```

### 実装チェックリスト

- [ ] マイグレーション作成・実行
- [ ] PatientConsent モデルにスナップショットロジック追加
- [ ] ConsentItemResponse モデルにスナップショットロジック追加
- [ ] ビュー修正（show.html.erb, index.html.erb）
- [ ] PDF生成サービス修正
- [ ] Model Spec 追加（スナップショット検証）
- [ ] Service Spec 更新（PDF生成検証）
- [ ] 全テスト実行・パス確認
- [ ] RuboCop 実行

---

## 🎯 タスク2: 署名漏れ時のバリデーション改善

### 背景・目的

**現状の問題**:
- Step 2で署名なしで「同意する」を押すとサーバー側エラー
- エラー時に入力情報（チェック項目）が失われる可能性

### 実装手順

#### Step 1: クライアント側バリデーション追加

**app/javascript/controllers/signature_controller.js**:
```javascript
// 署名データの存在チェック
hasSignature() {
  return this.signatureDataTarget.value !== '';
}

// フォーム送信前のバリデーション
validateBeforeSubmit(event) {
  if (!this.hasSignature()) {
    event.preventDefault();
    alert('署名をお願いします。上記のキャンバスに署名を描いてください。');
    return false;
  }
  return true;
}
```

**app/views/patient_consents/new.html.erb**:
```erb
<%= form.submit '同意する',
    data: {
      action: 'click->signature#validateBeforeSubmit',
      turbo_confirm: '内容を確認し、同意しますか？'
    },
    class: '...' %>
```

#### Step 2: エラーメッセージ改善

**app/models/patient_consent.rb**:
```ruby
validates :signature_data, presence: { message: '署名が必要です' }
```

**app/views/patient_consents/new.html.erb**:
```erb
<% if @patient_consent&.errors&.any? %>
  <div class="alert alert-error">
    <h3>エラーが発生しました</h3>
    <ul>
      <% @patient_consent.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### 実装チェックリスト

- [ ] Stimulus コントローラーにバリデーション追加
- [ ] エラーメッセージ改善
- [ ] System Spec 追加（署名なし送信のテスト）
- [ ] 全テスト実行・パス確認

---

## 🎯 タスク3: 看護師確認フロー追加

### 背景・目的

**背景**:
- 患者署名後、看護師が内容を確認してから正式に同意完了とする運用フロー

**メリット**:
- 医療現場の実運用フローに合致
- ダブルチェック体制で記入漏れ・誤記入を防止
- 法的証拠性の向上

### 実装手順

#### Step 1: マイグレーション作成

```bash
rails g migration AddNurseConfirmedToPatientConsents nurse_confirmed:boolean
```

**マイグレーション内容**:
```ruby
add_column :patient_consents, :nurse_confirmed, :boolean, default: false, null: false
```

#### Step 2: モデル変更

**app/models/patient_consent.rb**:
```ruby
validates :nurse_confirmed, acceptance: {
  message: '看護師による確認が必要です'
}, on: :create
```

#### Step 3: ビュー変更

**app/views/patient_consents/new.html.erb**:

Step 2に看護師確認セクション追加:
```erb
<!-- 患者署名後の説明 -->
<div class="alert alert-info mb-4">
  <p>
    署名が終わりましたら、担当看護師が確認いたしますので、しばらく今の状態でお待ちいただくか、
    再度内容をご確認ください。別途書類を発行いたします。
  </p>
</div>

<!-- 看護師確認チェックボックス -->
<div class="form-control mb-4">
  <%= form.check_box :nurse_confirmed,
      class: "checkbox checkbox-primary",
      id: "consent_#{index}_nurse_confirmed" %>
  <%= form.label :nurse_confirmed,
      '看護師確認済み（看護師がチェックしてください）',
      class: "label cursor-pointer",
      for: "consent_#{index}_nurse_confirmed" %>
</div>
```

#### Step 4: コントローラー変更

**app/controllers/patient_consents_controller.rb**:
```ruby
def permit_consent_params(params)
  params.permit(
    :consent_form_template_id,
    :facility_doctor_id,
    :signature_data,
    :nurse_confirmed, # 追加
    consent_item_responses_attributes: %i[consent_form_item_id checked]
  )
end
```

#### Step 5: テスト追加

**spec/models/patient_consent_spec.rb**:
```ruby
describe 'バリデーション' do
  it 'nurse_confirmed が false の場合、作成できない' do
    consent = build(:patient_consent, nurse_confirmed: false)
    expect(consent).not_to be_valid
    expect(consent.errors[:nurse_confirmed]).to include('看護師による確認が必要です')
  end

  it 'nurse_confirmed が true の場合、作成できる' do
    consent = build(:patient_consent, nurse_confirmed: true)
    expect(consent).to be_valid
  end
end
```

**spec/system/patient_consents_spec.rb**:
```ruby
it '看護師確認なしでは同意書を作成できない' do
  # ... 署名まで実施

  # 看護師確認チェックなし
  click_button '同意する'

  expect(page).to have_content('看護師による確認が必要です')
end

it '看護師確認ありで同意書を作成できる' do
  # ... 署名まで実施

  # 看護師確認チェック
  check '看護師確認済み'
  click_button '同意する'

  expect(page).to have_content('同意書を作成しました')
end
```

### 実装チェックリスト

- [ ] マイグレーション作成・実行
- [ ] モデルにバリデーション追加
- [ ] ビューに看護師確認UI追加
- [ ] コントローラーに nurse_confirmed パラメータ追加
- [ ] Model Spec 追加
- [ ] System Spec 追加
- [ ] 全テスト実行・パス確認

---

## 📊 全体の進捗管理

### タスク進捗

| タスク | 状態 | 完了日 |
|-------|------|--------|
| タスク1: スナップショット化 | 未着手 | - |
| タスク2: バリデーション改善 | 未着手 | - |
| タスク3: 看護師確認フロー | 未着手 | - |

### テスト統計

- **開始時**: 683 examples, 0 failures
- **現在**: （未実施）
- **目標**: 全テストパス、カバレッジ95%以上維持

### コード品質

- **RuboCop**: （未実施）
- **Brakeman**: （未実施）

---

## 🚀 次のステップ

1. **タスク1実装開始**: スナップショット化（最優先）
2. マイグレーション作成・実行
3. モデル・ビュー・サービス修正
4. テスト追加・全テスト実行
5. タスク2・3へ進む

---

**作成者**: Claude
**最終更新**: 2025-10-19
