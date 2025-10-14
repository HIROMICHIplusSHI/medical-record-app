require 'rails_helper'

RSpec.describe QuestionnairesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }

  before { sign_in user }

  describe 'POST #create' do
    context 'バリデーション実行のテスト' do
      it '問診票作成時に患者情報が同期される' do
        questionnaire_params = {
          full_name: '新しい太郎',
          phone: '090-9999-9999',
          birth_date: '1990-01-01',
          gender: 'male',
        }

        post :create, params: { patient_id: patient.id, questionnaire: questionnaire_params }

        patient.reload
        expect(patient.name).to eq('新しい太郎')
        expect(patient.phone).to eq('090-9999-9999')
      end

      it '不正な電話番号の場合はバリデーションエラーをログに記録する' do
        questionnaire_params = {
          full_name: 'テスト太郎',
          phone: '12345', # 不正な電話番号形式
          birth_date: '1990-01-01',
          gender: 'male',
        }

        # バリデーションエラーログが記録されることを確認
        expect(Rails.logger).to receive(:warn).with(/Patient sync validation failed/)

        post :create, params: { patient_id: patient.id, questionnaire: questionnaire_params }
      end

      it 'バリデーションエラー時は患者情報を更新しない' do
        original_name = patient.name

        questionnaire_params = {
          full_name: '新しい太郎',
          phone: 'invalid-phone', # 不正な電話番号
          birth_date: '1990-01-01',
          gender: 'male',
        }

        post :create, params: { patient_id: patient.id, questionnaire: questionnaire_params }

        patient.reload
        # 患者名は更新されていない（バリデーションエラーのため）
        expect(patient.name).to eq(original_name)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:questionnaire) { create(:questionnaire, patient: patient) }

    context 'バリデーション実行のテスト' do
      it '問診票更新時に患者情報が同期される' do
        update_params = {
          full_name: '更新太郎',
          phone: '080-8888-8888',
        }

        patch :update, params: { patient_id: patient.id, questionnaire: update_params }

        patient.reload
        expect(patient.name).to eq('更新太郎')
        expect(patient.phone).to eq('080-8888-8888')
      end

      it '不正なデータの場合はバリデーションエラーをログに記録する' do
        update_params = {
          full_name: 'テスト太郎',
          phone: 'abc', # 不正な電話番号
        }

        expect(Rails.logger).to receive(:warn).with(/Patient sync validation failed/)

        patch :update, params: { patient_id: patient.id, questionnaire: update_params }
      end
    end
  end
end
