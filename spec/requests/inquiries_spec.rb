require 'rails_helper'

RSpec.describe 'Inquiries', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /inquiries' do
    let!(:inquiries) { create_list(:inquiry, 3, user: user) }
    let!(:other_user_inquiry) { create(:inquiry) }

    it 'お問い合わせ一覧が表示される' do
      get inquiries_path
      expect(response).to have_http_status(:success)
    end

    it '自分のお問い合わせのみ表示される' do
      get inquiries_path
      expect(response.body).to include(inquiries.first.subject)
      expect(response.body).not_to include(other_user_inquiry.subject)
    end

    it '更新日時の降順で表示される' do
      get inquiries_path
      expect(response.body.index(inquiries.last.subject)).to be < response.body.index(inquiries.first.subject)
    end
  end

  describe 'GET /inquiries/:id' do
    let(:inquiry) { create(:inquiry, :with_messages, user: user) }

    it 'お問い合わせ詳細が表示される' do
      get inquiry_path(inquiry)
      expect(response).to have_http_status(:success)
    end

    it 'メッセージが作成日時の昇順で表示される' do
      get inquiry_path(inquiry)
      messages = inquiry.inquiry_messages.chronological
      expect(response.body.index(messages.first.body)).to be < response.body.index(messages.last.body)
    end

    context '他のユーザーのお問い合わせの場合' do
      let(:other_inquiry) { create(:inquiry) }

      it 'アクセスできない' do
        get inquiry_path(other_inquiry)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inquiries_path)
      end
    end
  end

  describe 'GET /inquiries/new' do
    it '新規お問い合わせフォームが表示される' do
      get new_inquiry_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /inquiries' do
    let(:valid_attributes) do
      {
        inquiry: {
          subject: 'テストお問い合わせ',
          body: 'お問い合わせ内容です。',
        },
      }
    end

    let(:invalid_attributes) do
      {
        inquiry: {
          subject: '',
          body: '',
        },
      }
    end

    context '正常なパラメータの場合' do
      it 'お問い合わせが作成される' do
        expect do
          post inquiries_path, params: valid_attributes
        end.to change(Inquiry, :count).by(1).and change(InquiryMessage, :count).by(1)
      end

      it 'お問い合わせ詳細ページにリダイレクトされる' do
        post inquiries_path, params: valid_attributes
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inquiry_path(Inquiry.last))
      end

      it '成功メッセージが表示される' do
        post inquiries_path, params: valid_attributes
        follow_redirect!
        expect(response.body).to include('お問い合わせを送信しました')
      end
    end

    context '不正なパラメータの場合' do
      it 'お問い合わせが作成されない' do
        expect do
          post inquiries_path, params: invalid_attributes
        end.not_to change(Inquiry, :count)
      end

      it '新規作成フォームが再表示される' do
        post inquiries_path, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'エラーメッセージが表示される' do
        post inquiries_path, params: invalid_attributes
        expect(response.body).to include('件名を入力してください')
      end
    end

    context 'トランザクション失敗時' do
      it 'ユーザーフレンドリーなエラーメッセージが表示される' do
        allow_any_instance_of(InquiryMessage).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new
        )

        post inquiries_path, params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('お問い合わせの送信に失敗しました')
        expect(response.body).not_to include('ActiveRecord')
        expect(response.body).not_to include('RecordInvalid')
      end
    end

    context 'Mass Assignment対策' do
      it 'statusパラメータは無視される' do
        mass_assignment_params = valid_attributes.deep_merge(
          inquiry: { status: 'closed' }
        )

        post inquiries_path, params: mass_assignment_params

        created_inquiry = Inquiry.last
        expect(created_inquiry.status).to eq('open') # デフォルト値
        expect(created_inquiry.status).not_to eq('closed')
      end

      it 'user_idパラメータは無視される' do
        other_user = create(:user)
        mass_assignment_params = valid_attributes.deep_merge(
          inquiry: { user_id: other_user.id }
        )

        post inquiries_path, params: mass_assignment_params

        created_inquiry = Inquiry.last
        expect(created_inquiry.user_id).to eq(user.id) # ログインユーザー
        expect(created_inquiry.user_id).not_to eq(other_user.id)
      end
    end
  end

  describe '認証なしの場合' do
    before do
      sign_out user
    end

    it 'ログインページにリダイレクトされる' do
      get inquiries_path
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
