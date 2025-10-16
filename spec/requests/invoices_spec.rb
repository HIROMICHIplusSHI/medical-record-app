require 'rails_helper'

RSpec.describe 'Invoices', type: :request do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:invoice) { create(:invoice, user: user, facility: facility) }

  describe '認証チェック' do
    context '未ログイン時' do
      it 'GET /invoices は ログインページにリダイレクトする' do
        get invoices_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'GET /invoices/:id は ログインページにリダイレクトする' do
        get invoice_path(invoice)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'GET /invoices/new は ログインページにリダイレクトする' do
        get new_invoice_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'POST /invoices は ログインページにリダイレクトする' do
        post invoices_path, params: { invoice: { facility_id: facility.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /invoices' do
    before { sign_in user }

    it '正常にレスポンスを返す' do
      get invoices_path
      expect(response).to have_http_status(:success)
    end

    it '自分の請求書のみ表示される' do
      my_invoice = create(:invoice, user: user)
      other_user = create(:user, email: 'other@example.com')
      other_invoice = create(:invoice, user: other_user)

      get invoices_path
      expect(response.body).to include(my_invoice.invoice_number)
      expect(response.body).not_to include(other_invoice.invoice_number)
    end

    it 'ページネーションが動作する' do
      create_list(:invoice, 25, user: user)

      get invoices_path
      # 20件表示される（ページネーション）
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /invoices/:id' do
    before { sign_in user }

    context '自分の請求書の場合' do
      it '正常にレスポンスを返す' do
        get invoice_path(invoice)
        expect(response).to have_http_status(:success)
      end

      it '請求書明細が含まれる' do
        items = create_list(:invoice_item, 3, invoice: invoice)

        get invoice_path(invoice)
        items.each do |item|
          expect(response.body).to include(item.description)
        end
      end
    end

    context '他人の請求書の場合' do
      let(:other_user) { create(:user, email: 'other@example.com') }
      let(:other_invoice) { create(:invoice, user: other_user) }

      it '404エラーになる' do
        get invoice_path(other_invoice)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /invoices/new' do
    before { sign_in user }

    it '正常にレスポンスを返す' do
      get new_invoice_path
      expect(response).to have_http_status(:success)
    end

    it '施設一覧が取得される' do
      facilities = create_list(:facility, 3)

      get new_invoice_path
      facilities.each do |facility|
        expect(response.body).to include(facility.name)
      end
    end
  end

  describe 'POST /invoices' do
    before { sign_in user }

    let(:valid_attributes) do
      {
        facility_id: facility.id,
        billing_period_start: Date.current.beginning_of_month,
        billing_period_end: Date.current.end_of_month,
      }
    end

    context '有効なパラメータの場合' do
      it '請求書が作成される' do
        # InvoiceGeneratorが動作するようにカルテを作成
        patient = create(:patient)
        create(:medical_record,
               user: user,
               facility: facility,
               patient: patient,
               visit_date: Date.current)

        expect do
          post invoices_path, params: { invoice: valid_attributes }
        end.to change(Invoice, :count).by(1)
      end

      it '請求書詳細ページにリダイレクトする' do
        patient = create(:patient)
        create(:medical_record,
               user: user,
               facility: facility,
               patient: patient,
               visit_date: Date.current)

        post invoices_path, params: { invoice: valid_attributes }
        expect(response).to redirect_to(invoice_path(Invoice.last))
      end

      it '成功メッセージが表示される' do
        patient = create(:patient)
        create(:medical_record,
               user: user,
               facility: facility,
               patient: patient,
               visit_date: Date.current)

        post invoices_path, params: { invoice: valid_attributes }
        follow_redirect!
        expect(response.body).to include('請求書を作成しました')
      end
    end

    context '無効なパラメータの場合' do
      it '請求書が作成されない' do
        invalid_attributes = valid_attributes.merge(billing_period_end: nil)

        expect do
          post invoices_path, params: { invoice: invalid_attributes }
        end.not_to change(Invoice, :count)
      end

      it 'newテンプレートを再表示する' do
        invalid_attributes = valid_attributes.merge(billing_period_end: nil)

        post invoices_path, params: { invoice: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /invoices/:id/edit' do
    before { sign_in user }

    it '正常にレスポンスを返す' do
      get edit_invoice_path(invoice)
      expect(response).to have_http_status(:success)
    end

    it '施設一覧が取得される' do
      facilities = create_list(:facility, 3)

      get edit_invoice_path(invoice)
      facilities.each do |facility|
        expect(response.body).to include(facility.name)
      end
    end
  end

  describe 'PATCH /invoices/:id' do
    before { sign_in user }

    context '有効なパラメータの場合' do
      it '請求書が更新される' do
        patch invoice_path(invoice), params: { invoice: { status: :issued } }
        invoice.reload
        expect(invoice.status).to eq('issued')
      end

      it '請求書詳細ページにリダイレクトする' do
        patch invoice_path(invoice), params: { invoice: { status: :issued } }
        expect(response).to redirect_to(invoice_path(invoice))
      end

      it '成功メッセージが表示される' do
        patch invoice_path(invoice), params: { invoice: { status: :issued } }
        follow_redirect!
        expect(response.body).to include('請求書を更新しました')
      end
    end

    context '無効なパラメータの場合' do
      it '請求書が更新されない' do
        patch invoice_path(invoice), params: { invoice: { billing_period_end: nil } }
        invoice.reload
        expect(invoice.billing_period_end).not_to be_nil
      end

      it 'editテンプレートを再表示する' do
        patch invoice_path(invoice), params: { invoice: { billing_period_end: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /invoices/:id' do
    before { sign_in user }

    it '請求書が削除される' do
      invoice # let で作成

      expect do
        delete invoice_path(invoice)
      end.to change(Invoice, :count).by(-1)
    end

    it '請求書一覧ページにリダイレクトする' do
      delete invoice_path(invoice)
      expect(response).to redirect_to(invoices_path)
    end

    it '成功メッセージが表示される' do
      delete invoice_path(invoice)
      follow_redirect!
      expect(response.body).to include('請求書を削除しました')
    end
  end
end
