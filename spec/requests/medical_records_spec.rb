require 'rails_helper'

RSpec.describe 'MedicalRecords', type: :request do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:facility) { create(:facility, user: user) }
  let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

  before do
    sign_in user
  end

  describe 'GET /medical_records' do
    it '正常にレスポンスを返す' do
      get medical_records_path
      expect(response).to have_http_status(:success)
    end

    it 'カルテ一覧が表示される' do
      create(:medical_record, user: user, patient: patient, facility: facility, chief_complaint: '主訴A')
      create(:medical_record, user: user, patient: patient, facility: facility, chief_complaint: '主訴B')
      get medical_records_path
      expect(response.body).to include('主訴A')
      expect(response.body).to include('主訴B')
    end
  end

  describe 'GET /medical_records/:id' do
    it '正常にレスポンスを返す' do
      get medical_record_path(medical_record)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /medical_records/new' do
    it '正常にレスポンスを返す' do
      get new_medical_record_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /medical_records/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_medical_record_path(medical_record)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /medical_records' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          medical_record: {
            patient_id: patient.id,
            facility_id: facility.id,
            visit_date: Date.today,
            treatment_location: '顔全体',
            chief_complaint: 'しわが気になる',
            diagnosis: '加齢による皮膚の弾力低下',
            treatment_content: 'ボトックス注射を実施',
            notes: '経過観察',
          },
        }
      end

      it 'カルテが作成される' do
        expect do
          post medical_records_path, params: valid_params
        end.to change(MedicalRecord, :count).by(1)
      end

      it '作成されたカルテのユーザーが正しい' do
        post medical_records_path, params: valid_params
        expect(MedicalRecord.last.user).to eq(user)
      end

      it '詳細ページにリダイレクトされる' do
        post medical_records_path, params: valid_params
        expect(response).to redirect_to(medical_record_path(MedicalRecord.last))
      end
    end

    context 'コスト項目を含むパラメータの場合' do
      let(:valid_params_with_costs) do
        {
          medical_record: {
            patient_id: patient.id,
            facility_id: facility.id,
            visit_date: Date.today,
            treatment_location: '顔全体',
            chief_complaint: 'しわが気になる',
            diagnosis: '加齢による皮膚の弾力低下',
            treatment_content: 'ボトックス注射を実施',
            cost_items_attributes: [
              { item_name: 'ボトックス注射', quantity: 1, unit_price: 50000 },
              { item_name: 'ヒアルロン酸注射', quantity: 2, unit_price: 30000 }
            ]
          }
        }
      end

      it 'カルテとコスト項目が同時に作成される' do
        expect do
          post medical_records_path, params: valid_params_with_costs
        end.to change(MedicalRecord, :count).by(1)
           .and change(CostItem, :count).by(2)
      end

      it '作成されたカルテの合計金額が正しい' do
        post medical_records_path, params: valid_params_with_costs
        expect(MedicalRecord.last.total_cost).to eq(110000)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          medical_record: {
            patient_id: nil,
            visit_date: nil,
            treatment_location: '',
            chief_complaint: '',
            diagnosis: '',
            treatment_content: '',
          },
        }
      end

      it 'カルテが作成されない' do
        expect do
          post medical_records_path, params: invalid_params
        end.not_to change(MedicalRecord, :count)
      end

      it 'newテンプレートが再表示される' do
        post medical_records_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /medical_records/:id' do
    context '有効なパラメータの場合' do
      let(:update_params) do
        {
          medical_record: {
            chief_complaint: '更新された主訴',
          },
        }
      end

      it 'カルテが更新される' do
        patch medical_record_path(medical_record), params: update_params
        medical_record.reload
        expect(medical_record.chief_complaint).to eq('更新された主訴')
      end

      it '詳細ページにリダイレクトされる' do
        patch medical_record_path(medical_record), params: update_params
        expect(response).to redirect_to(medical_record_path(medical_record))
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          medical_record: {
            chief_complaint: '',
          },
        }
      end

      it 'カルテが更新されない' do
        original_complaint = medical_record.chief_complaint
        patch medical_record_path(medical_record), params: invalid_params
        medical_record.reload
        expect(medical_record.chief_complaint).to eq(original_complaint)
      end

      it 'editテンプレートが再表示される' do
        patch medical_record_path(medical_record), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /medical_records/:id' do
    it 'カルテが削除される' do
      record_to_delete = create(:medical_record, user: user, patient: patient, facility: facility)
      expect do
        delete medical_record_path(record_to_delete)
      end.to change(MedicalRecord, :count).by(-1)
    end

    it '一覧ページにリダイレクトされる' do
      delete medical_record_path(medical_record)
      expect(response).to redirect_to(medical_records_path)
    end
  end

  describe '他のユーザーのリソースへのアクセス' do
    let(:other_user) { create(:user) }
    let(:other_patient) { create(:patient, user: other_user) }
    let(:other_facility) { create(:facility, user: other_user) }
    let(:other_record) { create(:medical_record, user: other_user, patient: other_patient, facility: other_facility) }

    it '他のユーザーのカルテを表示できない' do
      get medical_record_path(other_record)
      expect(response).to have_http_status(:not_found)
    end

    it '他のユーザーのカルテを編集できない' do
      get edit_medical_record_path(other_record)
      expect(response).to have_http_status(:not_found)
    end

    it '他のユーザーのカルテを更新できない' do
      original_complaint = other_record.chief_complaint
      patch medical_record_path(other_record), params: { medical_record: { chief_complaint: 'hacked' } }
      expect(response).to have_http_status(:not_found)
      expect(other_record.reload.chief_complaint).to eq(original_complaint)
    end

    it '他のユーザーのカルテを削除できない' do
      other_record_id = other_record.id
      delete medical_record_path(other_record)
      expect(response).to have_http_status(:not_found)
      expect(MedicalRecord.exists?(other_record_id)).to be true
    end
  end

  describe '認証なしでのアクセス' do
    before do
      sign_out user
    end

    it '一覧ページにアクセスできない' do
      get medical_records_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it '新規作成ページにアクセスできない' do
      get new_medical_record_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
