require 'rails_helper'

RSpec.describe 'UserDashboards', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /dashboard' do
    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get user_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みの場合' do
      before { sign_in user }

      it 'ダッシュボードページが表示される' do
        get user_dashboard_path
        expect(response).to have_http_status(:success)
      end

      it 'アクティブなお知らせが表示される' do
        create(:announcement, :published, author: admin, published_at: 1.day.ago,
                                          title: 'テストお知らせ')
        create(:announcement, :draft, author: admin)

        get user_dashboard_path

        expect(response.body).to include('テストお知らせ')
      end
    end
  end
end
