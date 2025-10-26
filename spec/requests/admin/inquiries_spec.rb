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

        context 'エッジケース' do
          it '空文字列の場合、すべてのお問い合わせが表示される' do
            get admin_inquiries_path, params: { status: '' }

            expect(response).to have_http_status(:success)
            expect(response.body).to include(open_inquiry.subject)
            expect(response.body).to include(closed_inquiry.subject)
          end

          it 'nilの場合、すべてのお問い合わせが表示される' do
            get admin_inquiries_path, params: { status: nil }

            expect(response).to have_http_status(:success)
            expect(response.body).to include(open_inquiry.subject)
            expect(response.body).to include(closed_inquiry.subject)
          end

          it 'SQLインジェクション試行値の場合、すべてのお問い合わせが表示される' do
            get admin_inquiries_path, params: { status: "'; DROP TABLE inquiries; --" }

            expect(response).to have_http_status(:success)
            expect(response.body).to include(open_inquiry.subject)
            expect(response.body).to include(closed_inquiry.subject)
          end
        end
      end

      context 'カテゴリフィルタ' do
        let!(:general_inquiry) { create(:inquiry, category: :general, subject: '一般的な質問') }
        let!(:bug_inquiry) { create(:inquiry, category: :bug_report, subject: '不具合報告') }

        it 'カテゴリでフィルタリングできる' do
          get admin_inquiries_path, params: { category: 'general' }
          expect(response.body).to include(general_inquiry.subject)
          expect(response.body).not_to include(bug_inquiry.subject)
        end

        it '無効なカテゴリ値の場合、すべてのお問い合わせが表示される' do
          get admin_inquiries_path, params: { category: 'invalid_category' }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(general_inquiry.subject)
          expect(response.body).to include(bug_inquiry.subject)
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

      context '既読処理' do
        it '問い合わせを開くとadmin_read_atが更新される' do
          inquiry.update(admin_read_at: nil)

          expect do
            get admin_inquiry_path(inquiry)
          end.to change { inquiry.reload.admin_read_at }.from(nil)
        end

        it '再度開くとadmin_read_atが再更新される' do
          inquiry.update(admin_read_at: 1.hour.ago)
          initial_read_at = inquiry.reload.admin_read_at

          expect do
            get admin_inquiry_path(inquiry)
          end.to change { inquiry.reload.admin_read_at }.from(initial_read_at)
        end
      end

      context 'ステータス自動更新' do
        it 'openステータスの場合、in_progressに変更される' do
          inquiry.update(status: :open)

          get admin_inquiry_path(inquiry)

          expect(inquiry.reload.status).to eq('in_progress')
        end

        it 'in_progressステータスの場合、変更されない' do
          inquiry.update(status: :in_progress)

          expect do
            get admin_inquiry_path(inquiry)
          end.not_to(change { inquiry.reload.status })
        end

        it 'closedステータスの場合、変更されない' do
          inquiry.update(status: :closed)

          expect do
            get admin_inquiry_path(inquiry)
          end.not_to(change { inquiry.reload.status })
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
      expect(response).to redirect_to(user_dashboard_path)
    end

    it 'お問い合わせ詳細にアクセスできない' do
      inquiry = create(:inquiry)
      get admin_inquiry_path(inquiry)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(user_dashboard_path)
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
