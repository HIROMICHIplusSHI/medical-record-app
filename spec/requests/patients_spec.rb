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

    context '検索機能' do
      let!(:patient1) { create(:patient, user: user, name: '山田太郎', phone: '090-1234-5678') }
      let!(:patient2) { create(:patient, user: user, name: '田中花子', phone: '080-9876-5432') }
      let!(:patient3) { create(:patient, user: user, name: '佐藤次郎', phone: '070-1111-2222') }

      it '氏名で検索できる' do
        get patients_path, params: { query: '山田' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('山田太郎')
        expect(response.body).not_to include('田中花子')
        expect(response.body).not_to include('佐藤次郎')
      end

      it '電話番号で検索できる' do
        get patients_path, params: { query: '090' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('山田太郎')
        expect(response.body).not_to include('田中花子')
        expect(response.body).not_to include('佐藤次郎')
      end

      it '部分一致で検索できる' do
        get patients_path, params: { query: '田' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('山田太郎')
        expect(response.body).to include('田中花子')
        expect(response.body).not_to include('佐藤次郎')
      end

      it '検索クエリが空の場合は全ての患者を表示する' do
        get patients_path, params: { query: '' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('山田太郎')
        expect(response.body).to include('田中花子')
        expect(response.body).to include('佐藤次郎')
      end

      it 'マッチする患者がいない場合は何も表示しない' do
        get patients_path, params: { query: '存在しない患者' }
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('山田太郎')
        expect(response.body).not_to include('田中花子')
        expect(response.body).not_to include('佐藤次郎')
      end
    end

    context 'ページネーション' do
      it 'デフォルトで25件ずつ表示する' do
        # created_atを明示的に設定してソート順を確定
        # 明示的な名前を使用して他のテストとの干渉を防ぐ
        # patients[0] = 1秒前, patients[29] = 30秒前
        patients = (1..30).map do |i|
          create(:patient, user: user, name: "ページ1テスト患者#{format('%02d', i)}", created_at: i.seconds.ago)
        end
        get patients_path
        expect(response).to have_http_status(:success)
        # recentスコープで降順なので、最初の25件（1-25秒前、配列で0-24）が表示される
        patients.first(25).each do |patient|
          expect(response.body).to include(patient.name)
        end
        # 最後の5件（26-30秒前、配列で25-29）は表示されない
        patients.last(5).each do |patient|
          expect(response.body).not_to include(patient.name)
        end
      end

      it 'pageパラメータで2ページ目を表示できる' do
        # created_atを明示的に設定してソート順を確定
        # 明示的な名前を使用して他のテストとの干渉を防ぐ
        # patients[0] = 1秒前, patients[29] = 30秒前
        patients = (1..30).map do |i|
          create(:patient, user: user, name: "ページ2テスト患者#{format('%02d', i)}", created_at: i.seconds.ago)
        end
        get patients_path, params: { page: 2 }
        expect(response).to have_http_status(:success)
        # recentスコープで降順なので、2ページ目には最後の5件（26-30秒前、配列で25-29）が表示される
        patients.last(5).each do |patient|
          expect(response.body).to include(patient.name)
        end
        # 最初の25件（1-25秒前、配列で0-24）は表示されない
        patients.first(25).each do |patient|
          expect(response.body).not_to include(patient.name)
        end
      end

      it '検索結果にもページネーションが適用される' do
        # 検索でヒットする患者30名（created_atを明示的に設定）
        # search_patients[0] = 1秒前, search_patients[29] = 30秒前
        search_patients = (1..30).map do |i|
          create(:patient, user: user, name: "検索テスト患者#{format('%02d', i)}", created_at: i.seconds.ago)
        end
        # ヒットしない患者5名
        create_list(:patient, 5, user: user, name: '別の患者')

        get patients_path, params: { query: '検索テスト' }
        expect(response).to have_http_status(:success)
        # recentスコープで降順なので、最初の25件（1-25秒前、配列で0-24）が表示される
        search_patients.first(25).each do |patient|
          expect(response.body).to include(patient.name)
        end
        # 最後の5件（26-30秒前、配列で25-29）は表示されない
        search_patients.last(5).each do |patient|
          expect(response.body).not_to include(patient.name)
        end
      end
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

  describe 'GET /patients/:id の施術履歴セクション' do
    let(:facility) { create(:facility, user: user) }

    it '患者の施術履歴が表示される' do
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2026, 3, 1), treatment_content: 'アイブロウ施術')

      get patient_path(patient)

      expect(response.body).to include('施術履歴')
      expect(response.body).to include('アイブロウ施術')
    end

    it '施術記録が無い場合は空状態を表示する' do
      get patient_path(patient)

      expect(response.body).to include('まだ施術記録がありません')
    end

    # 杭: 患者ページには当該患者の施術記録だけが並ぶ（他患者の記録が混ざらない）
    it '同じユーザーの他患者の施術記録は表示されない' do
      another_patient = create(:patient, user: user, name: '別患者')
      create(:medical_record, user: user, patient: another_patient, facility: facility,
                              treatment_content: '別患者の施術内容')

      get patient_path(patient)

      expect(response.body).not_to include('別患者の施術内容')
    end

    # 杭1（強化）: 患者が自分のものでも、施術記録の所有者が他ユーザーなら表示しない。
    # 越境作成されたレコードが被害者の画面に注入されるのを防ぐ。
    it '他ユーザーが作成した施術記録は表示されない' do
      foreign_user = create(:user)
      foreign_facility = create(:facility, user: foreign_user)
      # 所有者一致のバリデーション導入前に作られた越境データを再現する（多層防御の確認）
      MedicalRecord.new(user: foreign_user, patient: patient, facility: foreign_facility,
                        visit_date: Date.current,
                        treatment_content: '他ユーザーが作成した内容').save(validate: false)

      get patient_path(patient)

      expect(response.body).not_to include('他ユーザーが作成した内容')
      expect(response.body).to include('まだ施術記録がありません')
    end

    it '施術履歴は来院日の新しい順に並ぶ' do
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2020, 1, 1), treatment_content: '最も古い施術')
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2026, 1, 1), treatment_content: '最も新しい施術')

      get patient_path(patient)

      expect(response.body.index('最も新しい施術')).to be < response.body.index('最も古い施術')
    end

    it '表示は最大5件までで、超過分は一覧へ誘導する' do
      6.times do |i|
        create(:medical_record, user: user, patient: patient, facility: facility,
                                visit_date: Date.new(2026, 1, i + 1), treatment_content: "施術#{i + 1}")
      end

      get patient_path(patient)

      # 新しい順に5件（施術6〜施術2）が出て、最も古い「施術1」は出ない
      expect(response.body).to include('施術6')
      expect(response.body).not_to include('施術1<')
      expect(response.body).to include('全6件')
    end

    # 杭1の逆方向（混入だけでなく欠落もしない）
    it '当該患者の施術記録が欠落しない' do
      3.times do |i|
        create(:medical_record, user: user, patient: patient, facility: facility,
                                treatment_content: "欠落確認#{i}")
      end

      get patient_path(patient)

      3.times { |i| expect(response.body).to include("欠落確認#{i}") }
    end

    it '施術記録がある場合は施術履歴一覧への導線がある' do
      create(:medical_record, user: user, patient: patient, facility: facility)

      get patient_path(patient)

      expect(response.body).to include('すべての施術履歴を見る')
      expect(response.body).to include(patient_medical_records_path(patient))
    end

    it '施術記録が無い場合は一覧への導線を出さない' do
      get patient_path(patient)

      expect(response.body).not_to include('すべての施術履歴を見る')
    end

    it '施術記録の有無によらず施術記録の追加導線がある' do
      get patient_path(patient)

      expect(response.body).to include(new_patient_medical_record_path(patient))
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
