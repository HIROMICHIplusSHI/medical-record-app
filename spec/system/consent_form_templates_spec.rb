require 'rails_helper'

RSpec.describe 'ConsentFormTemplates', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '同意書テンプレート管理', js: true do
    context '新規作成' do
      it '同意書テンプレートを作成できる' do
        visit new_consent_form_template_path

        fill_in 'タイトル', with: 'アートメイク施術同意書'
        fill_in '説明文', with: '施術前に必ずご確認ください。'
        check '使用中'

        click_button '保存'

        expect(page).to have_content('同意書テンプレートが正常に作成されました')
        expect(page).to have_content('アートメイク施術同意書')
      end
    end

    context '編集' do
      let!(:template) { create(:consent_form_template, user: user, title: '既存テンプレート') }

      it '同意書テンプレートを編集できる' do
        visit edit_consent_form_template_path(template)

        fill_in 'タイトル', with: '更新されたテンプレート'
        click_button '保存'

        expect(page).to have_content('同意書テンプレートが正常に更新されました')
        expect(page).to have_content('更新されたテンプレート')
      end
    end

    context '削除' do
      let!(:template) { create(:consent_form_template, user: user, title: '削除するテンプレート') }

      it '同意書テンプレートを削除できる' do
        visit edit_consent_form_template_path(template)

        accept_confirm do
          click_button 'テンプレートを削除'
        end

        expect(page).to have_content('同意書テンプレートが正常に削除されました')
        expect(page).not_to have_content('削除するテンプレート')
      end
    end
  end

  describe 'チェック項目の動的フォーム', js: true do
    context '新規作成時' do
      it 'チェック項目を動的に追加できる' do
        visit new_consent_form_template_path

        fill_in 'タイトル', with: 'テストテンプレート'

        # 最初はチェック項目が0件
        expect(page).to have_selector('.consent-form-item-row', count: 0)

        # チェック項目を追加
        click_button '項目を追加'
        expect(page).to have_selector('.consent-form-item-row', count: 1)

        # チェック項目を入力（表示順は自動設定されるのでreadonly）
        within all('.consent-form-item-row').last do
          fill_in '項目内容', with: '施術にはリスクがあることを理解しました'
          check '必須項目'
        end

        # もう1つ追加
        click_button '項目を追加'
        expect(page).to have_selector('.consent-form-item-row', count: 2)

        within all('.consent-form-item-row').last do
          fill_in '項目内容', with: 'アレルギーの有無を正しく申告しました'
        end

        # 保存
        click_button '保存'

        expect(page).to have_content('同意書テンプレートが正常に作成されました')

        # チェック項目が保存されたことを確認
        template = ConsentFormTemplate.last
        expect(template.consent_form_items.count).to eq(2)
        expect(template.consent_form_items.pluck(:content)).to include(
          '施術にはリスクがあることを理解しました',
          'アレルギーの有無を正しく申告しました'
        )
      end

      it '追加したチェック項目フィールドを削除できる' do
        visit new_consent_form_template_path

        fill_in 'タイトル', with: 'テストテンプレート'

        # チェック項目を2つ追加
        click_button '項目を追加'
        click_button '項目を追加'

        expect(page).to have_selector('.consent-form-item-row', count: 2)

        # 1つ目を削除
        within all('.consent-form-item-row').first do
          find('button[data-action="click->nested-form#removeItem"]').click
        end

        # 削除後は1件のみ表示
        expect(page).to have_selector('.consent-form-item-row:not([style*="display: none"])', count: 1)
      end
    end

    context '編集時' do
      let!(:template) do
        create(:consent_form_template, user: user, title: '既存テンプレート').tap do |t|
          create(:consent_form_item, consent_form_template: t, content: '既存項目1', position: 1)
          create(:consent_form_item, consent_form_template: t, content: '既存項目2', position: 2)
        end
      end

      it '既存のチェック項目が表示される' do
        visit edit_consent_form_template_path(template)

        expect(page).to have_selector('.consent-form-item-row', count: 2)
        expect(page).to have_field('項目内容', with: '既存項目1')
        expect(page).to have_field('項目内容', with: '既存項目2')
      end

      it '既存項目を更新し、新規項目を追加できる' do
        visit edit_consent_form_template_path(template)

        # 既存項目を更新
        within all('.consent-form-item-row').first do
          fill_in '項目内容', with: '更新された項目1'
        end

        # 新規項目を追加
        click_button '項目を追加'
        expect(page).to have_selector('.consent-form-item-row', count: 3)

        within all('.consent-form-item-row').last do
          fill_in '項目内容', with: '新規項目3'
        end

        click_button '保存'

        expect(page).to have_content('同意書テンプレートが正常に更新されました')

        template.reload
        expect(template.consent_form_items.count).to eq(3)
        expect(template.consent_form_items.pluck(:content)).to include('更新された項目1', '既存項目2', '新規項目3')
      end

      it '既存項目を削除できる' do
        visit edit_consent_form_template_path(template)

        expect(page).to have_selector('.consent-form-item-row', count: 2)

        # 1つ目を削除
        within all('.consent-form-item-row').first do
          find('button[data-action="click->nested-form#removeItem"]').click
        end

        # 削除後は非表示
        expect(page).to have_selector('.consent-form-item-row:not([style*="display: none"])', count: 1)

        click_button '保存'

        expect(page).to have_content('同意書テンプレートが正常に更新されました')

        template.reload
        expect(template.consent_form_items.count).to eq(1)
        expect(template.consent_form_items.first.content).to eq('既存項目2')
      end
    end
  end
end
