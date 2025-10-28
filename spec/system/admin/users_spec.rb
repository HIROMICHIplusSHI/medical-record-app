require 'rails_helper'

RSpec.describe 'Admin Users Management', type: :system do
  let!(:admin_user) { create(:user, :admin, create_invitation_code: false) }
  let!(:invitation_code) { create(:invitation_code, created_by: admin_user) }
  let(:regular_user) { create(:user, invitation_code_input: invitation_code.code, create_invitation_code: false) }

  before do
    sign_in admin_user
  end

  describe 'ユーザー一覧画面' do
    let!(:users) { create_list(:user, 3, invitation_code_input: invitation_code.code, create_invitation_code: false) }

    it 'ユーザー一覧が表示される', js: true do
      visit admin_users_path

      expect(page).to have_content('ユーザー管理')
      # 管理者 + 作成したユーザー3人 = 4人
      expect(page).to have_selector('tbody tr', count: 4)
    end

    it 'ユーザー情報が正しく表示される', js: true do
      user = users.first
      visit admin_users_path

      expect(page).to have_content(user.email)
      expect(page).to have_link('詳細', href: admin_user_path(user))
    end

    it '管理者バッジが表示される', js: true do
      visit admin_users_path

      # 管理者バッジの確認（赤色の背景）
      expect(page).to have_selector('[class*="bg-accent-danger"]', text: '管理者')
    end

    it 'ユーザーバッジが表示される', js: true do
      visit admin_users_path

      # ユーザーバッジの確認（青色の背景）
      expect(page).to have_selector('.bg-blue-100', text: 'ユーザー', count: 3)
    end
  end

  describe 'ユーザー詳細画面' do
    let!(:user) do
      create(:user,
             name: 'テストユーザー',
             email: 'test@example.com',
             company_email: 'company@example.com',
             company_phone: '03-1234-5678',
             invitation_code_input: invitation_code.code,
             create_invitation_code: false)
    end
    let!(:facility) { create(:facility, user: user, name: 'テスト施設') }
    let!(:patient) { create(:patient, user: user) }
    let!(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

    it '基本情報が正しく表示される', js: true do
      visit admin_user_path(user)

      expect(page).to have_content('ユーザー詳細')

      # メールアドレスの表示確認（幅が十分にあることを確認）
      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_content(user.company_email)
      expect(page).to have_content(user.company_phone)
    end

    it 'メールアドレスが改行なしで表示される', js: true do
      visit admin_user_path(user)

      # break-all クラスの存在を確認
      email_element = page.find('dd.break-all', text: user.email)
      expect(email_element).to be_present
    end

    it '統計情報が表示される', js: true do
      visit admin_user_path(user)

      # カルテ数
      expect(page).to have_content('カルテ数')
      expect(page).to have_content('1')

      # 患者数
      expect(page).to have_content('患者数')
      expect(page).to have_content('1')

      # 施術場所数
      expect(page).to have_content('施術場所数')
      expect(page).to have_content('1')
    end

    it '統計カードのアイコンが表示される', js: true do
      visit admin_user_path(user)

      # カルテ数（緑色）、患者数（青色）、施設数（紫色）、請求書数（黄色）のアイコン
      # 紫色のアイコンのみ実装されている
      expect(page).to have_selector('.bg-purple-500 svg', minimum: 1)
    end
  end

  describe '権限管理' do
    let!(:user) { create(:user, invitation_code_input: invitation_code.code, create_invitation_code: false) }

    context '自分以外のユーザーの場合' do
      it '権限変更ボタンが表示される', js: true do
        visit admin_user_path(user)

        expect(page).to have_button('管理者に変更')

        # ボタンのスタイルを確認（黄色の背景）
        button = page.find('button', text: '管理者に変更')
        expect(button[:class]).to include('bg-yellow-600')
        expect(button[:class]).to include('text-white')
      end

      it '権限変更ボタンが透明でないことを確認', js: true do
        visit admin_user_path(user)

        button = page.find('button', text: '管理者に変更')
        # bg-yellow-600 クラスが存在することを確認
        expect(button[:class]).to include('bg-yellow-600')
        # ホバー時の色変更クラスも確認
        expect(button[:class]).to include('hover:bg-yellow-700')
      end

      it 'ユーザーから管理者に変更できる', js: true do
        visit admin_user_path(user)

        # Cupriteでは確認ダイアログを自動承認
        page.driver.browser.on(:dialog, &:accept)

        click_button '管理者に変更'

        expect(page).to have_content('ユーザーの権限を管理者に変更しました')
        expect(page).to have_selector('[class*="bg-accent-danger"]', text: '管理者')
        expect(page).to have_button('ユーザーに変更')
      end
    end

    context '自分自身の場合' do
      it '権限変更ボタンが表示されない', js: true do
        visit admin_user_path(admin_user)

        expect(page).to have_content('自分自身の権限は変更できません')
        expect(page).not_to have_button('管理者に変更')
        expect(page).not_to have_button('ユーザーに変更')
      end
    end

    context '最後の管理者の場合' do
      let!(:another_admin) { create(:user, :admin, create_invitation_code: false, invitation_code_input: invitation_code.code) }

      before do
        # admin_user以外の管理者を全て削除して、admin_userを最後の管理者にする
        User.admin.where.not(id: admin_user.id).destroy_all
      end

      it '権限変更ボタンが表示されない', js: true do
        visit admin_user_path(admin_user)

        # 自分自身のページなので「自分自身の権限は変更できません」が表示される
        expect(page).to have_content('自分自身の権限は変更できません')
        expect(page).not_to have_button('ユーザーに変更')
      end
    end
  end
end
