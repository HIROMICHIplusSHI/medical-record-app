require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'ダッシュボードが表示される' do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it '統計情報が表示される' do
        create_list(:user, 3)
        create_list(:medical_record, 5, user: user)
        create_list(:announcement, 2, :published, author: admin)

        get admin_root_path

        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_root_path
        expect(response).to redirect_to(user_dashboard_path)
        follow_redirect!
        expect(response.body).to include('管理者権限が必要です')
      end
    end

    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
