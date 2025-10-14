require 'rails_helper'

RSpec.describe 'Questionnaires', type: :request do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:other_user) { create(:user) }
  let(:other_patient) { create(:patient, user: other_user) }

  before { sign_in user }

  describe 'GET /patients/:patient_id/questionnaire/new' do
    context '認証済みユーザーの場合' do
      it '問診票作成フォームが表示される' do
        get new_patient_questionnaire_path(patient)
        expect(response).to have_http_status(:success)
      end

      it '患者の基本情報が問診票フォームに事前入力される' do
        get new_patient_questionnaire_path(patient)
        expect(response.body).to include("value=\"#{patient.name}\"")
        expect(response.body).to include(patient.phone)
      end

      it '他のユーザーの患者の問診票は作成できない' do
        get new_patient_questionnaire_path(other_patient)
        expect(response).to redirect_to(patients_path)
      end
    end

    context '未認証ユーザーの場合' do
      before { sign_out user }

      it 'ログインページにリダイレクトされる' do
        get new_patient_questionnaire_path(patient)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /patients/:patient_id/questionnaire' do
    let(:valid_attributes) do
      {
        full_name: '佐藤 次郎',
        full_name_kana: 'サトウ ジロウ',
        birth_date: '1980-03-15',
        gender: 'male',
        phone: '080-1111-2222',
        email: 'jiro@example.com',
        postal_code: '150-0001',
        address: '東京都渋谷区2-2-2',
        emergency_contact: '佐藤花子（妻） 080-3333-4444',
        medical_conditions: '高血圧、治療中',
        current_medications: '降圧剤を服用中',
        allergies: '特になし',
        past_surgeries: '虫垂炎手術（2010年）',
        pregnancy_info: '該当なし',
        desired_treatments: '眉毛アートメイク',
        past_treatments: 'なし',
        skin_conditions: '普通肌',
        other_concerns: '自然な仕上がりを希望',
      }
    end

    context '有効なパラメータの場合' do
      it '問診票が作成される' do
        expect do
          post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        end.to change(Questionnaire, :count).by(1)
      end

      it '患者詳細ページにリダイレクトされる' do
        post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        expect(response).to redirect_to(patient_path(patient))
      end

      it '成功メッセージが表示される' do
        post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        follow_redirect!
        expect(response.body).to include('問診票が正常に登録されました。')
      end

      it '問診票の基本情報が患者レコードに自動同期される' do
        post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        patient.reload
        expect(patient.name).to eq('佐藤 次郎')
        expect(patient.date_of_birth.to_s).to eq('1980-03-15')
        expect(patient.gender).to eq('male')
        expect(patient.phone).to eq('080-1111-2222')
      end

      it '問診票の基本情報が一部nilでも同期時にエラーにならない' do
        minimal_attributes = {
          full_name: '最小 太郎',
          phone: '080-5555-6666',
          medical_conditions: 'なし',
          allergies: 'なし',
        }
        expect do
          post patient_questionnaire_path(patient), params: { questionnaire: minimal_attributes }
        end.to change(Questionnaire, :count).by(1)

        patient.reload
        expect(patient.name).to eq('最小 太郎')
        expect(patient.phone).to eq('080-5555-6666')
      end
    end

    context '他のユーザーの患者の場合' do
      it '問診票は作成されない' do
        expect do
          post patient_questionnaire_path(other_patient), params: { questionnaire: valid_attributes }
        end.not_to change(Questionnaire, :count)
      end

      it '患者一覧ページにリダイレクトされる' do
        post patient_questionnaire_path(other_patient), params: { questionnaire: valid_attributes }
        expect(response).to redirect_to(patients_path)
      end
    end

    context '既に問診票が存在する場合' do
      before { create(:questionnaire, patient: patient) }

      it '問診票は作成されない' do
        expect do
          post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        end.not_to change(Questionnaire, :count)
      end

      it '編集ページにリダイレクトされる' do
        post patient_questionnaire_path(patient), params: { questionnaire: valid_attributes }
        expect(response).to redirect_to(edit_patient_questionnaire_path(patient))
      end
    end
  end

  describe 'GET /patients/:patient_id/questionnaire/edit' do
    let!(:questionnaire) { create(:questionnaire, patient: patient) }

    context '認証済みユーザーの場合' do
      it '問診票編集フォームが表示される' do
        get edit_patient_questionnaire_path(patient)
        expect(response).to have_http_status(:success)
      end

      it '他のユーザーの患者の問診票は編集できない' do
        create(:questionnaire, patient: other_patient)
        get edit_patient_questionnaire_path(other_patient)
        expect(response).to redirect_to(patients_path)
      end
    end

    context '問診票が存在しない場合' do
      before { questionnaire.destroy }

      it '問診票作成ページにリダイレクトされる' do
        get edit_patient_questionnaire_path(patient)
        expect(response).to redirect_to(new_patient_questionnaire_path(patient))
      end
    end
  end

  describe 'PATCH /patients/:patient_id/questionnaire' do
    let!(:questionnaire) { create(:questionnaire, patient: patient) }
    let(:new_attributes) do
      {
        medical_conditions: '更新された既往歴',
        other_concerns: '更新された相談内容',
      }
    end
    let(:new_basic_info_attributes) do
      {
        full_name: '更新 太郎',
        full_name_kana: 'コウシン タロウ',
        birth_date: '1985-06-20',
        gender: 'female',
        phone: '090-9999-8888',
      }
    end

    context '有効なパラメータの場合' do
      it '問診票が更新される' do
        patch patient_questionnaire_path(patient), params: { questionnaire: new_attributes }
        questionnaire.reload
        expect(questionnaire.medical_conditions).to eq('更新された既往歴')
        expect(questionnaire.other_concerns).to eq('更新された相談内容')
      end

      it '患者詳細ページにリダイレクトされる' do
        patch patient_questionnaire_path(patient), params: { questionnaire: new_attributes }
        expect(response).to redirect_to(patient_path(patient))
      end

      it '成功メッセージが表示される' do
        patch patient_questionnaire_path(patient), params: { questionnaire: new_attributes }
        follow_redirect!
        expect(response.body).to include('問診票が正常に更新されました。')
      end

      it '問診票の基本情報が更新されたら患者レコードにも自動同期される' do
        patch patient_questionnaire_path(patient), params: { questionnaire: new_basic_info_attributes }
        patient.reload
        expect(patient.name).to eq('更新 太郎')
        expect(patient.date_of_birth.to_s).to eq('1985-06-20')
        expect(patient.gender).to eq('female')
        expect(patient.phone).to eq('090-9999-8888')
      end
    end

    context '他のユーザーの患者の場合' do
      let!(:other_questionnaire) { create(:questionnaire, patient: other_patient) }

      it '問診票は更新されない' do
        original_conditions = other_questionnaire.medical_conditions
        patch patient_questionnaire_path(other_patient), params: { questionnaire: new_attributes }
        other_questionnaire.reload
        expect(other_questionnaire.medical_conditions).to eq(original_conditions)
      end

      it '患者一覧ページにリダイレクトされる' do
        patch patient_questionnaire_path(other_patient), params: { questionnaire: new_attributes }
        expect(response).to redirect_to(patients_path)
      end
    end
  end

  describe 'DELETE /patients/:patient_id/questionnaire' do
    let!(:questionnaire) { create(:questionnaire, patient: patient) }

    context '認証済みユーザーの場合' do
      it '問診票が削除される' do
        expect do
          delete patient_questionnaire_path(patient)
        end.to change(Questionnaire, :count).by(-1)
      end

      it '患者詳細ページにリダイレクトされる' do
        delete patient_questionnaire_path(patient)
        expect(response).to redirect_to(patient_path(patient))
      end

      it '成功メッセージが表示される' do
        delete patient_questionnaire_path(patient)
        follow_redirect!
        expect(response.body).to include('問診票が正常に削除されました。')
      end
    end

    context '他のユーザーの患者の場合' do
      let!(:other_questionnaire) { create(:questionnaire, patient: other_patient) }

      it '問診票は削除されない' do
        expect do
          delete patient_questionnaire_path(other_patient)
        end.not_to change(Questionnaire, :count)
      end

      it '患者一覧ページにリダイレクトされる' do
        delete patient_questionnaire_path(other_patient)
        expect(response).to redirect_to(patients_path)
      end
    end
  end
end
