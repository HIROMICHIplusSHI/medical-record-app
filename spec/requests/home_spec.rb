require 'rails_helper'

RSpec.describe 'Homes', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /' do
    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みの場合' do
      before { sign_in user }

      it 'ホームページが表示される' do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it 'アクティブなお知らせが表示される' do
        create(:announcement, :published, author: admin, published_at: 1.day.ago,
                                          title: 'テストお知らせ')
        create(:announcement, :draft, author: admin)

        get root_path

        expect(response.body).to include('テストお知らせ')
      end
    end
  end

  describe 'GET /home' do
    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get home_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みの場合' do
      before { sign_in user }

      it 'ホームページが表示される' do
        get home_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /home/dismiss_announcement' do
    let(:announcement) { create(:announcement, :published, author: admin, published_at: 1.day.ago) }

    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        post home_dismiss_announcement_path, params: { announcement_id: announcement.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みの場合' do
      before { sign_in user }

      it 'セッションにお知らせIDが保存される' do
        post home_dismiss_announcement_path, params: { announcement_id: announcement.id }
        expect(session[:dismissed_announcements]).to include(announcement.id)
      end

      it '200 OKを返す' do
        post home_dismiss_announcement_path, params: { announcement_id: announcement.id }
        expect(response).to have_http_status(:ok)
      end

      it '重複してIDを保存しない' do
        # 最初のリクエストでIDを保存
        post home_dismiss_announcement_path, params: { announcement_id: announcement.id }
        # 2回目のリクエスト
        post home_dismiss_announcement_path, params: { announcement_id: announcement.id }
        # セッションに1回だけ保存されていることを確認（別のリクエストで確認）
        get home_path
        expect(controller.session[:dismissed_announcements].count(announcement.id)).to eq(1)
      end
    end
  end
end
