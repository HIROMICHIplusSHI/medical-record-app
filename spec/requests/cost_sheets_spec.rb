require 'rails_helper'

RSpec.describe 'CostSheets', type: :request do
  let(:user) { create(:user) }
  let(:cost_sheet) { create(:cost_sheet, user: user) }

  before do
    sign_in user
  end

  describe 'GET /cost_sheets' do
    it '正常にレスポンスを返す' do
      get cost_sheets_path
      expect(response).to have_http_status(:success)
    end

    it 'コストシート一覧が表示される' do
      create(:cost_sheet, user: user, item_name: '施術A')
      create(:cost_sheet, user: user, item_name: '施術B')
      get cost_sheets_path
      expect(response.body).to include('施術A')
      expect(response.body).to include('施術B')
    end
  end

  describe 'GET /cost_sheets/new' do
    it '正常にレスポンスを返す' do
      get new_cost_sheet_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /cost_sheets/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_cost_sheet_path(cost_sheet)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /cost_sheets' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          cost_sheet: {
            item_name: '新しい施術',
            standard_price: 10_000,
            category: 'treatment',
            memo: 'テストメモ',
          },
        }
      end

      it 'コストシートが作成される' do
        expect do
          post cost_sheets_path, params: valid_params
        end.to change(CostSheet, :count).by(1)
      end

      it '作成されたコストシートのユーザーが正しい' do
        post cost_sheets_path, params: valid_params
        expect(CostSheet.last.user).to eq(user)
      end

      it '一覧ページにリダイレクトされる' do
        post cost_sheets_path, params: valid_params
        expect(response).to redirect_to(cost_sheets_path)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          cost_sheet: {
            item_name: '',
            standard_price: -1,
          },
        }
      end

      it 'コストシートが作成されない' do
        expect do
          post cost_sheets_path, params: invalid_params
        end.not_to change(CostSheet, :count)
      end

      it 'newテンプレートが再表示される' do
        post cost_sheets_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /cost_sheets/:id' do
    context '有効なパラメータの場合' do
      let(:update_params) do
        {
          cost_sheet: {
            item_name: '更新された施術',
          },
        }
      end

      it 'コストシートが更新される' do
        patch cost_sheet_path(cost_sheet), params: update_params
        cost_sheet.reload
        expect(cost_sheet.item_name).to eq('更新された施術')
      end

      it '一覧ページにリダイレクトされる' do
        patch cost_sheet_path(cost_sheet), params: update_params
        expect(response).to redirect_to(cost_sheets_path)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          cost_sheet: {
            item_name: '',
          },
        }
      end

      it 'コストシートが更新されない' do
        original_name = cost_sheet.item_name
        patch cost_sheet_path(cost_sheet), params: invalid_params
        cost_sheet.reload
        expect(cost_sheet.item_name).to eq(original_name)
      end

      it 'editテンプレートが再表示される' do
        patch cost_sheet_path(cost_sheet), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /cost_sheets/:id' do
    it 'コストシートが削除される' do
      cost_sheet_to_delete = create(:cost_sheet, user: user)
      expect do
        delete cost_sheet_path(cost_sheet_to_delete)
      end.to change(CostSheet, :count).by(-1)
    end

    it '一覧ページにリダイレクトされる' do
      delete cost_sheet_path(cost_sheet)
      expect(response).to redirect_to(cost_sheets_path)
    end
  end

  describe '認証なしでのアクセス' do
    before do
      sign_out user
    end

    it '一覧ページにアクセスできない' do
      get cost_sheets_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it '新規作成ページにアクセスできない' do
      get new_cost_sheet_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
