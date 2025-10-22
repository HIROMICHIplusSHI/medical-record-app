require 'rails_helper'

RSpec.describe 'InquiryMessages', type: :request do
  let(:user) { create(:user) }
  let(:inquiry) { create(:inquiry, user: user) }

  before do
    sign_in user
  end

  describe 'POST /inquiries/:inquiry_id/inquiry_messages' do
    let(:valid_attributes) do
      {
        inquiry_message: {
          body: '返信メッセージです。',
        },
      }
    end

    let(:invalid_attributes) do
      {
        inquiry_message: {
          body: '',
        },
      }
    end

    context '正常なパラメータの場合' do
      it 'メッセージが作成される' do
        expect do
          post inquiry_inquiry_messages_path(inquiry), params: valid_attributes
        end.to change(InquiryMessage, :count).by(1)
      end

      it 'お問い合わせ詳細ページにリダイレクトされる' do
        post inquiry_inquiry_messages_path(inquiry), params: valid_attributes
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inquiry_path(inquiry))
      end

      it '成功メッセージが表示される' do
        post inquiry_inquiry_messages_path(inquiry), params: valid_attributes
        follow_redirect!
        expect(response.body).to include('メッセージを送信しました')
      end

      it 'inquiryのupdated_atが更新される' do
        expect do
          post inquiry_inquiry_messages_path(inquiry), params: valid_attributes
        end.to(change { inquiry.reload.updated_at })
      end
    end

    context '不正なパラメータの場合' do
      it 'メッセージが作成されない' do
        expect do
          post inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
        end.not_to change(InquiryMessage, :count)
      end

      it 'お問い合わせ詳細ページが再表示される' do
        post inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'エラーメッセージが表示される' do
        post inquiry_inquiry_messages_path(inquiry), params: invalid_attributes
        expect(response.body).to include('本文を入力してください')
      end
    end

    context '他のユーザーのお問い合わせの場合' do
      let(:other_inquiry) { create(:inquiry) }

      it 'メッセージが作成されない' do
        expect do
          post inquiry_inquiry_messages_path(other_inquiry), params: valid_attributes
        end.not_to change(InquiryMessage, :count)
      end

      it 'お問い合わせ一覧にリダイレクトされる' do
        post inquiry_inquiry_messages_path(other_inquiry), params: valid_attributes
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inquiries_path)
      end
    end
  end

  describe '認証なしの場合' do
    before do
      sign_out user
    end

    it 'ログインページにリダイレクトされる' do
      post inquiry_inquiry_messages_path(inquiry), params: {
        inquiry_message: { body: 'テスト' },
      }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
