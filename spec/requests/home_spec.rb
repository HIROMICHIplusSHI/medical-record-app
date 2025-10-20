require 'rails_helper'

RSpec.describe 'Homes', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /' do
    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get user_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みの場合' do
      before { sign_in user }

      it 'ホームページが表示される' do
        get user_root_path
        expect(response).to have_http_status(:success)
      end

      it 'アクティブなお知らせが表示される' do
        create(:announcement, :published, author: admin, published_at: 1.day.ago,
                                          title: 'テストお知らせ')
        create(:announcement, :draft, author: admin)

        get user_root_path

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

      context 'エラーケース' do
        it '存在しないお知らせIDの場合、404を返す' do
          post home_dismiss_announcement_path, params: { announcement_id: 99_999 }
          expect(response).to have_http_status(:not_found)
        end

        it '非公開のお知らせの場合、403を返す' do
          draft_announcement = create(:announcement, author: admin, status: :draft)
          post home_dismiss_announcement_path, params: { announcement_id: draft_announcement.id }
          expect(response).to have_http_status(:forbidden)
        end

        it '期限切れのお知らせの場合、403を返す' do
          expired_announcement = create(:announcement, :published, author: admin,
                                                                   published_at: 2.days.ago,
                                                                   expires_at: 1.day.ago)
          post home_dismiss_announcement_path, params: { announcement_id: expired_announcement.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'セッション管理' do
        it 'セッションサイズが最大数を超えた場合、古いIDを削除する' do
          # 100個のお知らせを作成して非表示にする
          announcements = create_list(:announcement, 100, :published, author: admin, published_at: 1.day.ago)
          announcements.each do |ann|
            post home_dismiss_announcement_path, params: { announcement_id: ann.id }
          end

          # 101個目を追加
          new_announcement = create(:announcement, :published, author: admin, published_at: 1.day.ago)
          post home_dismiss_announcement_path, params: { announcement_id: new_announcement.id }

          get home_path
          # セッションサイズが100に制限されていることを確認
          expect(controller.session[:dismissed_announcements].size).to eq(100)
          # 最初のID（announcements[0].id）が削除されていることを確認
          expect(controller.session[:dismissed_announcements]).not_to include(announcements.first.id)
          # 新しいIDが追加されていることを確認
          expect(controller.session[:dismissed_announcements]).to include(new_announcement.id)
        end
      end
    end
  end
end
