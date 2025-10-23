require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin/users' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'ユーザー一覧が表示される' do
        create_list(:user, 3)

        get admin_users_path

        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_users_path
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'GET /admin/users/:id' do
    before { sign_in admin }

    it 'ユーザー詳細が表示される' do
      get admin_user_path(user)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /admin/users/:id/toggle_role' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'ユーザーの権限を変更できる' do
        patch toggle_role_admin_user_path(user)

        expect(user.reload.admin?).to be true
        expect(response).to redirect_to(admin_user_path(user))
        follow_redirect!
        expect(response.body).to include('管理者に変更しました')
      end

      it '管理者をユーザーに降格できる' do
        another_admin = create(:user, role: :admin)

        patch toggle_role_admin_user_path(another_admin)

        expect(another_admin.reload.user?).to be true
        expect(response).to redirect_to(admin_user_path(another_admin))
        follow_redirect!
        expect(response.body).to include('ユーザーに変更しました')
      end

      it '自分自身の権限は変更できない' do
        patch toggle_role_admin_user_path(admin)

        expect(admin.reload.admin?).to be true
        expect(response).to redirect_to(admin_user_path(admin))
        follow_redirect!
        expect(response.body).to include('自分自身の権限は変更できません')
      end

      it '最後の管理者の権限は変更できない' do
        # adminのみが管理者の状態
        patch toggle_role_admin_user_path(admin)

        expect(admin.reload.admin?).to be true
        expect(response).to redirect_to(admin_user_path(admin))
        follow_redirect!
        expect(response.body).to include('最後の管理者の権限は変更できません')
      end
    end
  end
end
