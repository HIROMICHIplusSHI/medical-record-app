require 'rails_helper'

RSpec.describe 'Admin::InquiryMessages', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:normal_user) { create(:user) }
  let(:inquiry) { create(:inquiry) }

  describe '管理者としてログイン' do
    before do
      sign_in admin_user
    end

    describe 'POST /admin/inquiries/:inquiry_id/inquiry_messages' do
      let(:valid_attributes) do
        {
          inquiry_message: {
            body: '管理者からの返信です。'
          }
        }
      end

      let(:invalid_attributes) do
        {
          inquiry_message: {
            body: ''
          }
        }
      end

      context '正常なパラメータの場合' do
        it 'メッセージが作成される' do
          expect {
            post admin_inquiry_inquiry_messages_path(inquiry), params: valid_attributes
          }.to change(InquiryMessage, :count).by(1)
        end

        it '管理者ユーザーが送信者になる' do
          post admin_inquiry_inquiry_messages_path(inquiry), params: valid_attributes
          expect(InquiryMessage.last.user).to eq(admin_user)
        end

        it 'お問い合わせ詳細ページにリダイレクトされる' do
          post admin_inquiry_inquiry_messages_path(inquiry), params: valid_attributes
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(admin_inquiry_path(inquiry))
        end

        it '成功メッセージが表示される' do
          post admin_inquiry_inquiry_messages_path(inquiry), params: valid_attributes
          follow_redirect!
          expect(response.body).to include('返信しました')
        end

        it 'inquiryのupdated_atが更新される' do
          expect {
            post admin_inquiry_inquiry_messages_path(inquiry), params: valid_attributes
          }.to change { inquiry.reload.updated_at }
        end
      end

      context '不正なパラメータの場合' do
        it 'メッセージが作成されない' do
          expect {
            post admin_inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
          }.not_to change(InquiryMessage, :count)
        end

        it 'お問い合わせ詳細ページが再表示される' do
          post admin_inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'エラーメッセージが表示される' do
          post admin_inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
          expect(response.body).to include('本文を入力してください')
        end
      end
    end
  end

  describe '一般ユーザーとしてログイン' do
    before do
      sign_in normal_user
    end

    it 'メッセージが作成されない' do
      expect {
        post admin_inquiry_inquiry_messages_path(inquiry), params: {
          inquiry_message: { body: 'テスト' }
        }
      }.not_to change(InquiryMessage, :count)
    end

    it 'ホームページにリダイレクトされる' do
      post admin_inquiry_inquiry_messages_path(inquiry), params: {
        inquiry_message: { body: 'テスト' }
      }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(user_root_path)
    end
  end

  describe '認証なしの場合' do
    it 'ログインページにリダイレクトされる' do
      post admin_inquiry_inquiry_messages_path(inquiry), params: {
        inquiry_message: { body: 'テスト' }
      }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
