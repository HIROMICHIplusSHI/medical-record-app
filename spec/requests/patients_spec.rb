require 'rails_helper'

RSpec.describe 'Patients', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:valid_attributes) do
    {
      name: '山田太郎',
      date_of_birth: '1990-01-01',
      gender: 'male',
      phone: '090-1234-5678',
      email: 'yamada@example.com',
      address: '東京都渋谷区1-1-1',
      emergency_contact: '03-1234-5678',
    }
  end
  let(:invalid_attributes) do
    {
      name: '',
      date_of_birth: 1.day.from_now,
      phone: 'invalid_phone',
      email: 'invalid_email',
    }
  end

  before do
    sign_in user
  end

  describe 'GET /patients' do
    it '正常にレスポンスを返す' do
      get patients_path
      expect(response).to have_http_status(:success)
    end

    it 'ユーザーの患者のみを表示する' do
      create(:patient, user: user, name: 'ユーザーの患者')
      create(:patient, user: other_user, name: '他のユーザーの患者')

      get patients_path
      expect(response.body).to include('ユーザーの患者')
      expect(response.body).not_to include('他のユーザーの患者')
    end
  end

  describe 'GET /patients/:id' do
    it '正常にレスポンスを返す' do
      get patient_path(patient)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーの患者にはアクセスできない' do
      other_patient = create(:patient, user: other_user)
      get patient_path(other_patient)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(patients_path)
    end
  end

  describe 'GET /patients/new' do
    it '正常にレスポンスを返す' do
      get new_patient_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /patients' do
    context '有効なパラメータの場合' do
      it '新しい患者を作成する' do
        expect do
          post patients_path, params: { patient: valid_attributes }
        end.to change(Patient, :count).by(1)
      end

      it '作成した患者にリダイレクトする' do
        post patients_path, params: { patient: valid_attributes }
        expect(response).to redirect_to(patient_path(Patient.last))
      end

      it '成功メッセージを表示する' do
        post patients_path, params: { patient: valid_attributes }
        follow_redirect!
        expect(response.body).to include('患者が正常に登録されました')
      end
    end

    context '無効なパラメータの場合' do
      it '患者を作成しない' do
        expect do
          post patients_path, params: { patient: invalid_attributes }
        end.not_to change(Patient, :count)
      end

      it 'newテンプレートを再表示する' do
        post patients_path, params: { patient: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /patients/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_patient_path(patient)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーの患者は編集できない' do
      other_patient = create(:patient, user: other_user)
      get edit_patient_path(other_patient)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(patients_path)
    end
  end

  describe 'PATCH /patients/:id' do
    context '有効なパラメータの場合' do
      let(:new_attributes) do
        {
          name: '更新された患者名',
          phone: '090-9999-8888',
        }
      end

      it '患者を更新する' do
        patch patient_path(patient), params: { patient: new_attributes }
        patient.reload
        expect(patient.name).to eq('更新された患者名')
        expect(patient.phone).to eq('090-9999-8888')
      end

      it '更新した患者にリダイレクトする' do
        patch patient_path(patient), params: { patient: new_attributes }
        expect(response).to redirect_to(patient_path(patient))
      end

      it '成功メッセージを表示する' do
        patch patient_path(patient), params: { patient: new_attributes }
        follow_redirect!
        expect(response.body).to include('患者情報が正常に更新されました')
      end
    end

    context '無効なパラメータの場合' do
      it '患者を更新しない' do
        original_name = patient.name
        patch patient_path(patient), params: { patient: invalid_attributes }
        patient.reload
        expect(patient.name).to eq(original_name)
      end

      it 'editテンプレートを再表示する' do
        patch patient_path(patient), params: { patient: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it '他のユーザーの患者は更新できない' do
      other_patient = create(:patient, user: other_user)
      patch patient_path(other_patient), params: { patient: { name: '不正な更新' } }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(patients_path)
    end
  end

  describe 'DELETE /patients/:id' do
    it '患者を削除する' do
      patient_to_delete = create(:patient, user: user)
      expect do
        delete patient_path(patient_to_delete)
      end.to change(Patient, :count).by(-1)
    end

    it '患者一覧にリダイレクトする' do
      delete patient_path(patient)
      expect(response).to redirect_to(patients_path)
    end

    it '成功メッセージを表示する' do
      delete patient_path(patient)
      follow_redirect!
      expect(response.body).to include('患者が正常に削除されました')
    end

    it '他のユーザーの患者は削除できない' do
      other_patient = create(:patient, user: other_user)
      expect do
        delete patient_path(other_patient)
      end.not_to change(Patient, :count)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(patients_path)
    end
  end

  describe '認証されていない場合' do
    before do
      sign_out user
    end

    it 'indexにアクセスできない' do
      get patients_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'showにアクセスできない' do
      get patient_path(patient)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'newにアクセスできない' do
      get new_patient_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'createにアクセスできない' do
      post patients_path, params: { patient: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'editにアクセスできない' do
      get edit_patient_path(patient)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updateにアクセスできない' do
      patch patient_path(patient), params: { patient: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroyにアクセスできない' do
      delete patient_path(patient)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
