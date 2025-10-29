require 'rails_helper'

RSpec.describe 'Admin Dashboard', type: :system do
  let!(:admin_user) { create(:user, :admin, create_invitation_code: false) }
  let!(:invitation_code) { create(:invitation_code, created_by: admin_user) }
  let(:regular_user) { create(:user, invitation_code_input: invitation_code.code, create_invitation_code: false) }

  describe 'アクセス制御' do
    context '管理者の場合' do
      before { sign_in admin_user }

      it 'ダッシュボードにアクセスできる', js: true do
        visit admin_root_path

        expect(page).to have_content('管理者ダッシュボード')
        expect(page).to have_current_path(admin_root_path)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in regular_user }

      it 'ダッシュボードにアクセスできない', js: true do
        visit admin_root_path

        expect(page).to have_content('管理者権限が必要です')
        expect(page).not_to have_current_path(admin_root_path)
      end
    end
  end

  describe '統計情報の表示' do
    before do
      sign_in admin_user
      # テストデータの作成
      create_list(:user, 3, invitation_code_input: invitation_code.code, create_invitation_code: false)
    end

    it '総ユーザー数が表示される', js: true do
      visit admin_root_path

      expect(page).to have_content('総ユーザー数')
      # 管理者1 + 作成したユーザー3 = 4
      expect(page).to have_content('4')
    end

    # SVGアイコンは未実装のためpending
    xit '統計カードにアイコンが表示される', js: true do
      visit admin_root_path

      # SVGアイコンの存在を確認（複数のカード）
      expect(page).to have_selector('.bg-blue-500 svg', count: 1)
      expect(page).to have_selector('.bg-green-500 svg', count: 1)
      expect(page).to have_selector('.bg-yellow-500 svg', count: 1)
    end
  end

  describe 'ナビゲーション' do
    before { sign_in admin_user }

    it 'ユーザー管理へのリンクが表示される', js: true do
      visit admin_root_path

      expect(page).to have_link('ユーザー管理へ', href: admin_users_path)
    end

    it 'お知らせ管理へのリンクが表示される', js: true do
      visit admin_root_path

      expect(page).to have_link('お知らせ管理へ', href: admin_announcements_path)
    end
  end
end
