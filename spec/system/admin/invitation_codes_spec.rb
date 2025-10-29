# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Invitation Codes Management', type: :system do
  let(:admin_user) { create(:user, :admin, create_invitation_code: false) }

  before do
    sign_in admin_user
  end

  describe '招待コード一覧画面' do
    let!(:active_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'ACTIVE123',
             status: :active,
             max_uses: 10,
             used_count: 3)
    end
    let!(:inactive_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'INACTIVE',
             status: :inactive)
    end

    it '招待コード一覧が表示される', js: true do
      visit admin_invitation_codes_path

      expect(page).to have_content('招待コード管理')
      expect(page).to have_selector('tbody tr', minimum: 2)
    end

    it '招待コード情報が正しく表示される', js: true do
      visit admin_invitation_codes_path

      # アクティブなコード
      expect(page).to have_content('ACTIVE123')
      expect(page).to have_selector('[class*="bg-accent-success"]', text: '有効')
      expect(page).to have_content('3 / 10')

      # 停止中のコード
      expect(page).to have_content('INACTIVE')
      expect(page).to have_selector('[class*="bg-greige-100"]', text: '停止')
    end

    it '新規作成ボタンが表示される', js: true do
      visit admin_invitation_codes_path

      expect(page).to have_link('新規作成', href: new_admin_invitation_code_path)
      button = page.find('a', text: '新規作成')
      expect(button[:class]).to include('bg-accent-primary')
    end

    it 'CSV出力ボタンが表示される', js: true do
      visit admin_invitation_codes_path

      expect(page).to have_link('CSV出力', href: export_admin_invitation_codes_path(format: :csv))
    end

    it '検索フォームが表示される', js: true do
      visit admin_invitation_codes_path

      expect(page).to have_field('q[code_cont]')
      expect(page).to have_select('q[status_eq]')
    end
  end

  describe '招待コード詳細画面' do
    let!(:invitation_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'DETAIL123',
             status: :active,
             max_uses: 20,
             used_count: 5,
             expires_at: 1.month.from_now,
             memo: 'テストメモ')
    end

    it '詳細情報が正しく表示される', js: true do
      visit admin_invitation_code_path(invitation_code)

      expect(page).to have_content('招待コード詳細')
      expect(page).to have_content('DETAIL123')
      expect(page).to have_content('20')
      expect(page).to have_content('5')
      expect(page).to have_content('テストメモ')
      expect(page).to have_content(admin_user.email)
    end

    it 'ステータスバッジが表示される', js: true do
      visit admin_invitation_code_path(invitation_code)

      status_badge = page.find('[class*="bg-accent-success"]', text: '有効')
      expect(status_badge).to be_present
    end

    it 'アクションボタンが表示される', js: true do
      visit admin_invitation_code_path(invitation_code)

      expect(page).to have_link('編集')
      expect(page).to have_button('停止する')
      expect(page).to have_button('削除する')
    end
  end

  describe '招待コード作成' do
    it '招待コードを作成できる', js: true do
      visit new_admin_invitation_code_path

      expect(page).to have_content('招待コード作成')

      fill_in 'invitation_code[code]', with: 'NEWCODE123'
      fill_in 'invitation_code[max_uses]', with: '15'

      click_button '作成する'

      expect(page).to have_current_path(admin_invitation_codes_path)
      expect(page).to have_content('招待コードを作成しました')
      expect(page).to have_content('NEWCODE123')
    end

    it 'バリデーションエラーが表示される', js: true do
      visit new_admin_invitation_code_path

      # HTML5バリデーションを無効化してサーバー側のバリデーションをテスト
      page.execute_script("document.querySelector('input[name=\"invitation_code[code]\"]').removeAttribute('required')")

      # コードを空にする
      fill_in 'invitation_code[code]', with: ''

      click_button '作成する'

      expect(page).to have_content('エラーがあります')
      expect(page).to have_content('コードを入力してください')
    end

    it '重複コードでエラーが表示される', js: true do
      create(:invitation_code, created_by: admin_user, code: 'DUPLICATE')

      visit new_admin_invitation_code_path

      fill_in 'invitation_code[code]', with: 'DUPLICATE'

      click_button '作成する'

      expect(page).to have_content('エラーがあります')
      expect(page).to have_content('コードはすでに存在します')
    end
  end

  describe '招待コード編集' do
    let!(:invitation_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'EDIT123',
             max_uses: 10)
    end

    it '招待コードを編集できる', js: true do
      visit edit_admin_invitation_code_path(invitation_code)

      expect(page).to have_content('招待コード編集')

      fill_in 'invitation_code[max_uses]', with: '25'

      click_button '更新する'

      expect(page).to have_current_path(admin_invitation_code_path(invitation_code))
      expect(page).to have_content('招待コードを更新しました')

      invitation_code.reload
      expect(invitation_code.max_uses).to eq(25)
    end
  end

  describe '招待コード削除' do
    let!(:invitation_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'DELETE123')
    end

    it '招待コードを削除できる', js: true do
      visit admin_invitation_code_path(invitation_code)

      accept_confirm do
        click_button '削除する'
      end

      expect(page).to have_current_path(admin_invitation_codes_path)
      expect(page).to have_content('招待コードを削除しました')
      expect(page).not_to have_content('DELETE123')
    end
  end

  describe '招待コードの停止' do
    let!(:active_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'SUSPEND123',
             status: :active)
    end

    it 'アクティブな招待コードを停止できる', js: true do
      visit admin_invitation_code_path(active_code)

      click_button '停止する'

      expect(page).to have_content('招待コードを停止しました')
      expect(page).to have_selector('[class*="bg-greige-100"]', text: '停止')

      active_code.reload
      expect(active_code.status).to eq('inactive')
    end

    context 'すでに停止中の招待コード' do
      let!(:inactive_code) do
        create(:invitation_code,
               created_by: admin_user,
               code: 'ALREADY_INACTIVE',
               status: :inactive)
      end

      # FIXME: Factory作成時のエラーを修正する必要あり
      xit 'すでに停止中の招待コードは停止できない', js: true do
        visit admin_invitation_code_path(inactive_code)

        click_button '停止する'

        expect(page).to have_content('この招待コードは既に停止されています')
      end
    end
  end

  describe '招待コードの有効化' do
    let!(:inactive_code) do
      create(:invitation_code,
             created_by: admin_user,
             code: 'ACTIVATE123',
             status: :inactive)
    end

    it '停止中の招待コードを有効化できる', js: true do
      visit admin_invitation_code_path(inactive_code)

      click_button '有効化する'

      expect(page).to have_content('招待コードを有効化しました')
      expect(page).to have_selector('[class*="bg-accent-success"]', text: '有効')

      inactive_code.reload
      expect(inactive_code.status).to eq('active')
    end

    context 'すでに有効な招待コード' do
      let!(:already_active_code) do
        create(:invitation_code,
               created_by: admin_user,
               code: 'ALREADY_ACTIVE',
               status: :active)
      end

      # FIXME: Factory作成時のエラーを修正する必要あり
      xit 'すでに有効な招待コードは有効化できない', js: true do
        visit admin_invitation_code_path(already_active_code)

        click_button '有効化する'

        expect(page).to have_content('この招待コードは既に有効です')
      end
    end
  end

  describe '検索機能' do
    let!(:code1) { create(:invitation_code, created_by: admin_user, code: 'SEARCH001', status: :active) }
    let!(:code2) { create(:invitation_code, created_by: admin_user, code: 'SEARCH002', status: :inactive) }
    let!(:code3) { create(:invitation_code, created_by: admin_user, code: 'OTHER123', status: :active) }

    it 'コードで検索できる', js: true do
      visit admin_invitation_codes_path

      fill_in 'q[code_cont]', with: 'SEARCH'
      click_button '検索'

      expect(page).to have_content('SEARCH001')
      expect(page).to have_content('SEARCH002')
      expect(page).not_to have_content('OTHER123')
    end

    it 'ステータスで絞り込める', js: true do
      visit admin_invitation_codes_path

      select '有効', from: 'q[status_eq]'
      click_button '検索'

      expect(page).to have_content('SEARCH001')
      expect(page).to have_content('OTHER123')
      expect(page).not_to have_content('SEARCH002')
    end
  end

  describe 'ナビゲーションメニュー' do
    it 'ヘッダーに招待コード管理リンクが表示される', js: true do
      visit admin_root_path

      within('header') do
        expect(page).to have_link('招待コード管理', href: admin_invitation_codes_path)
      end
    end

    it '招待コード管理リンクをクリックすると一覧画面に遷移する', js: true do
      visit admin_root_path

      within('header') do
        click_link '招待コード管理'
      end

      expect(page).to have_current_path(admin_invitation_codes_path)
      expect(page).to have_content('招待コード管理')
    end
  end
end
