require 'rails_helper'

RSpec.describe 'Facilities', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:facility) { create(:facility, user: user) }
  let(:valid_attributes) do
    {
      name: 'テスト施設',
      address: '東京都渋谷区1-1-1',
      phone: '03-1234-5678',
      email: 'test@example.com',
      notes: 'テスト用の施設',
    }
  end
  let(:invalid_attributes) do
    {
      name: '',
      phone: 'invalid_phone',
    }
  end

  before do
    sign_in user
  end

  describe 'GET /facilities' do
    it '正常にレスポンスを返す' do
      get facilities_path
      expect(response).to have_http_status(:success)
    end

    it 'ユーザーの施設のみを表示する' do
      create(:facility, user: user, name: 'ユーザーの施設')
      create(:facility, user: other_user, name: '他のユーザーの施設')

      get facilities_path
      expect(response.body).to include('ユーザーの施設')
      expect(response.body).not_to include('他のユーザーの施設')
    end
  end

  describe 'GET /facilities/:id' do
    it '正常にレスポンスを返す' do
      get facility_path(facility)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーの施設にはアクセスできない' do
      other_facility = create(:facility, user: other_user)
      get facility_path(other_facility)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(facilities_path)
    end
  end

  describe 'GET /facilities/new' do
    it '正常にレスポンスを返す' do
      get new_facility_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /facilities' do
    context '有効なパラメータの場合' do
      it '新しい施設を作成する' do
        expect do
          post facilities_path, params: { facility: valid_attributes }
        end.to change(Facility, :count).by(1)
      end

      it '作成した施設にリダイレクトする' do
        post facilities_path, params: { facility: valid_attributes }
        expect(response).to redirect_to(facility_path(Facility.last))
      end

      it '成功メッセージを表示する' do
        post facilities_path, params: { facility: valid_attributes }
        follow_redirect!
        expect(response.body).to include('施設が正常に作成されました')
      end
    end

    context '無効なパラメータの場合' do
      it '施設を作成しない' do
        expect do
          post facilities_path, params: { facility: invalid_attributes }
        end.not_to change(Facility, :count)
      end

      it 'newテンプレートを再表示する' do
        post facilities_path, params: { facility: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /facilities/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_facility_path(facility)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーの施設は編集できない' do
      other_facility = create(:facility, user: other_user)
      get edit_facility_path(other_facility)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(facilities_path)
    end
  end

  describe 'PATCH /facilities/:id' do
    context '有効なパラメータの場合' do
      let(:new_attributes) do
        {
          name: '更新された施設名',
          phone: '03-9999-8888',
        }
      end

      it '施設を更新する' do
        patch facility_path(facility), params: { facility: new_attributes }
        facility.reload
        expect(facility.name).to eq('更新された施設名')
        expect(facility.phone).to eq('03-9999-8888')
      end

      it '更新した施設にリダイレクトする' do
        patch facility_path(facility), params: { facility: new_attributes }
        expect(response).to redirect_to(facility_path(facility))
      end

      it '成功メッセージを表示する' do
        patch facility_path(facility), params: { facility: new_attributes }
        follow_redirect!
        expect(response.body).to include('施設が正常に更新されました')
      end
    end

    context '無効なパラメータの場合' do
      it '施設を更新しない' do
        original_name = facility.name
        patch facility_path(facility), params: { facility: invalid_attributes }
        facility.reload
        expect(facility.name).to eq(original_name)
      end

      it 'editテンプレートを再表示する' do
        patch facility_path(facility), params: { facility: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it '他のユーザーの施設は更新できない' do
      other_facility = create(:facility, user: other_user)
      patch facility_path(other_facility), params: { facility: { name: '不正な更新' } }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(facilities_path)
    end
  end

  describe 'DELETE /facilities/:id' do
    it '施設を削除する' do
      facility_to_delete = create(:facility, user: user)
      expect do
        delete facility_path(facility_to_delete)
      end.to change(Facility, :count).by(-1)
    end

    it '施設一覧にリダイレクトする' do
      delete facility_path(facility)
      expect(response).to redirect_to(facilities_path)
    end

    it '成功メッセージを表示する' do
      delete facility_path(facility)
      follow_redirect!
      expect(response.body).to include('施設が正常に削除されました')
    end

    it '他のユーザーの施設は削除できない' do
      other_facility = create(:facility, user: other_user)
      expect do
        delete facility_path(other_facility)
      end.not_to change(Facility, :count)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(facilities_path)
    end
  end

  describe '認証されていない場合' do
    before do
      sign_out user
    end

    it 'indexにアクセスできない' do
      get facilities_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'showにアクセスできない' do
      get facility_path(facility)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'newにアクセスできない' do
      get new_facility_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'createにアクセスできない' do
      post facilities_path, params: { facility: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'editにアクセスできない' do
      get edit_facility_path(facility)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updateにアクセスできない' do
      patch facility_path(facility), params: { facility: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroyにアクセスできない' do
      delete facility_path(facility)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
