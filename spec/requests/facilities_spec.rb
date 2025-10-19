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
    context '医師情報も同時に作成する場合' do
      let(:facility_with_doctors_attributes) do
        {
          name: 'テスト施設',
          address: '東京都渋谷区1-1-1',
          facility_doctors_attributes: [
            { name: '山田太郎', medical_license_number: 'DOC001', specialization: '美容外科' },
            { name: '佐藤花子', medical_license_number: 'DOC002', specialization: '皮膚科' },
          ],
        }
      end

      it '施設と医師を同時に作成する' do
        expect do
          post facilities_path, params: { facility: facility_with_doctors_attributes }
        end.to change(Facility, :count).by(1)
                                       .and change(FacilityDoctor, :count).by(2)
      end

      it '医師情報が正しく保存される' do
        post facilities_path, params: { facility: facility_with_doctors_attributes }
        facility = Facility.last
        expect(facility.facility_doctors.count).to eq(2)
        expect(facility.facility_doctors.first.name).to eq('山田太郎')
        expect(facility.facility_doctors.first.medical_license_number).to eq('DOC001')
      end
    end

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
    context '医師情報も同時に更新する場合' do
      let!(:facility_with_doctor) do
        create(:facility, user: user).tap do |f|
          create(:facility_doctor, facility: f, name: '既存医師')
        end
      end

      let(:update_with_doctors_attributes) do
        {
          name: '更新施設',
          facility_doctors_attributes: [
            { id: facility_with_doctor.facility_doctors.first.id, name: '更新された医師' },
            { name: '新規医師', medical_license_number: 'DOC003' },
          ],
        }
      end

      it '既存医師を更新し、新規医師を追加する' do
        expect do
          patch facility_path(facility_with_doctor), params: { facility: update_with_doctors_attributes }
        end.to change { facility_with_doctor.reload.facility_doctors.count }.by(1)

        expect(facility_with_doctor.facility_doctors.first.name).to eq('更新された医師')
        expect(facility_with_doctor.facility_doctors.last.name).to eq('新規医師')
      end

      it '医師を削除できる（_destroyフラグ）' do
        doctor_to_delete = facility_with_doctor.facility_doctors.first
        delete_attributes = {
          facility_doctors_attributes: [
            { id: doctor_to_delete.id, _destroy: '1' },
          ],
        }

        expect do
          patch facility_path(facility_with_doctor), params: { facility: delete_attributes }
        end.to change { facility_with_doctor.reload.facility_doctors.count }.by(-1)
      end
    end

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
