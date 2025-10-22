require 'rails_helper'

RSpec.describe 'Admin::Inquiries', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:normal_user) { create(:user) }

  describe '管理者としてログイン' do
    before do
      sign_in admin_user
    end

    describe 'GET /admin/inquiries' do
      let!(:inquiries) { create_list(:inquiry, 3) }

      it 'お問い合わせ一覧が表示される' do
        get admin_inquiries_path
        expect(response).to have_http_status(:success)
      end

      it '全ユーザーのお問い合わせが表示される' do
        get admin_inquiries_path
        inquiries.each do |inquiry|
          expect(response.body).to include(inquiry.subject)
        end
      end

      context 'ステータスフィルタ' do
        let!(:open_inquiry) { create(:inquiry, status: :open) }
        let!(:closed_inquiry) { create(:inquiry, status: :closed) }

        it 'ステータスでフィルタリングできる' do
          get admin_inquiries_path, params: { status: 'open' }
          expect(response.body).to include(open_inquiry.subject)
          expect(response.body).not_to include(closed_inquiry.subject)
        end

        it '無効なステータス値の場合、すべてのお問い合わせが表示される' do
          get admin_inquiries_path, params: { status: 'invalid_status' }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(open_inquiry.subject)
          expect(response.body).to include(closed_inquiry.subject)
        end
      end
    end

    describe 'GET /admin/inquiries/:id' do
      let(:inquiry) { create(:inquiry, :with_messages) }

      it 'お問い合わせ詳細が表示される' do
        get admin_inquiry_path(inquiry)
        expect(response).to have_http_status(:success)
      end

      it 'メッセージ履歴が表示される' do
        get admin_inquiry_path(inquiry)
        inquiry.inquiry_messages.each do |message|
          expect(response.body).to include(message.body)
        end
      end
    end

    describe 'PATCH /admin/inquiries/:id' do
      let(:inquiry) { create(:inquiry, status: :open) }

      context '正常なパラメータの場合' do
        it 'ステータスを更新できる' do
          patch admin_inquiry_path(inquiry), params: {
            inquiry: { status: 'in_progress' },
          }
          expect(inquiry.reload.status).to eq('in_progress')
        end

        it 'お問い合わせ詳細ページにリダイレクトされる' do
          patch admin_inquiry_path(inquiry), params: {
            inquiry: { status: 'closed' },
          }
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(admin_inquiry_path(inquiry))
        end

        it '成功メッセージが表示される' do
          patch admin_inquiry_path(inquiry), params: {
            inquiry: { status: 'closed' },
          }
          follow_redirect!
          expect(response.body).to include('ステータスを更新しました')
        end
      end
    end
  end

  describe '一般ユーザーとしてログイン' do
    before do
      sign_in normal_user
    end

    it 'お問い合わせ一覧にアクセスできない' do
      get admin_inquiries_path
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(user_root_path)
    end

    it 'お問い合わせ詳細にアクセスできない' do
      inquiry = create(:inquiry)
      get admin_inquiry_path(inquiry)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(user_root_path)
    end

    it 'ステータス更新ができない' do
      inquiry = create(:inquiry, status: :open)
      patch admin_inquiry_path(inquiry), params: {
        inquiry: { status: 'closed' },
      }
      expect(response).to have_http_status(:redirect)
      expect(inquiry.reload.status).to eq('open')
    end
  end

  describe '認証なしの場合' do
    it 'ログインページにリダイレクトされる' do
      get admin_inquiries_path
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
