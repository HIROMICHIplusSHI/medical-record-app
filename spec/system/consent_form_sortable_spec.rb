require 'rails_helper'

RSpec.describe 'ConsentFormItemsSortable', type: :system do
  let(:user) { create(:user) }
  let!(:template) do
    create(:consent_form_template, user: user, title: 'ソート可能テンプレート').tap do |t|
      create(:consent_form_item, consent_form_template: t, content: '項目1', position: 1)
      create(:consent_form_item, consent_form_template: t, content: '項目2', position: 2)
      create(:consent_form_item, consent_form_template: t, content: '項目3', position: 3)
    end
  end

  before do
    sign_in user
  end

  describe 'ドラッグ&ドロップによる並び替え', js: true do
    it '編集画面でSortable controllerが正しく初期化される' do
      visit edit_consent_form_template_path(template)

      # 初期状態の確認
      items = all('.consent-form-item-row')
      expect(items[0]).to have_field('項目内容', with: '項目1')
      expect(items[1]).to have_field('項目内容', with: '項目2')
      expect(items[2]).to have_field('項目内容', with: '項目3')

      # ドラッグハンドルが表示されていることを確認
      expect(page).to have_css('.drag-handle', count: 3)

      # Sortable controllerが適用されていることを確認
      expect(page).to have_css('[data-controller*="sortable"]')
      expect(page).to have_css('[data-sortable-url-value]')

      # 各項目にdata-id属性が設定されていることを確認
      items.each do |item|
        expect(item['data-id']).not_to be_nil
      end
    end

    it 'ドラッグハンドルにカーソルを合わせると掴めることを示すカーソルが表示される' do
      visit edit_consent_form_template_path(template)

      # ドラッグハンドルが正しいクラスを持っていることを確認
      expect(page).to have_css('.drag-handle.cursor-move')
    end

    it '新規作成時にはドラッグ&ドロップ機能が無効' do
      visit new_consent_form_template_path

      fill_in 'タイトル', with: '新規テンプレート'

      # チェック項目を追加
      click_button '項目を追加'

      # ドラッグハンドルは表示されるが、sortable controllerは適用されない
      expect(page).to have_css('.drag-handle')
      expect(page).not_to have_css('[data-controller*="sortable"]')
    end
  end
end
