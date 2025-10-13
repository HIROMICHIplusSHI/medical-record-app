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
              { item_name: 'ボトックス注射', quantity: 1, unit_price: 50_000 },
              { item_name: 'ヒアルロン酸注射', quantity: 2, unit_price: 30_000 },
            ],
          },
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
        expect(MedicalRecord.last.total_cost).to eq(110_000)
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

  describe '画像アップロード' do
    let(:valid_params) do
      {
        patient_id: patient.id,
        facility_id: facility.id,
        visit_date: Date.today,
        treatment_location: '顔全体',
        chief_complaint: 'しわが気になる',
        diagnosis: '加齢による皮膚の弾力低下',
        treatment_content: 'ボトックス注射を実施',
      }
    end

    it 'カルテ作成時に画像をアップロードできる' do
      expect do
        post medical_records_path, params: {
          medical_record: valid_params.merge(
            photos: [
              fixture_file_upload('spec/fixtures/files/sample_image.jpg', 'image/jpeg'),
            ]
          ),
        }
      end.to change(MedicalRecord, :count).by(1)

      medical_record = MedicalRecord.last
      expect(medical_record.photos).to be_attached
      expect(medical_record.photos.count).to eq(1)
    end

    it 'カルテ更新時に画像を追加できる' do
      patch medical_record_path(medical_record), params: {
        medical_record: {
          photos: [
            fixture_file_upload('spec/fixtures/files/sample_image.jpg', 'image/jpeg'),
          ],
        },
      }

      medical_record.reload
      expect(medical_record.photos).to be_attached
      expect(medical_record.photos.count).to eq(1)
    end

    it '6枚以上の画像はアップロードできない' do
      post medical_records_path, params: {
        medical_record: valid_params.merge(
          photos: 6.times.map do
            fixture_file_upload('spec/fixtures/files/sample_image.jpg', 'image/jpeg')
          end
        ),
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('は最大5枚までアップロードできます')
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

  describe 'Ransack検索機能' do
    let(:patient_a) { create(:patient, user: user, name: '山田太郎') }
    let(:patient_b) { create(:patient, user: user, name: '佐藤花子') }
    let(:facility_a) { create(:facility, user: user, name: '東京院') }
    let(:facility_b) { create(:facility, user: user, name: '大阪院') }
    let(:tag_a) { create(:tag, user: user, name: 'ボトックス') }
    let(:tag_b) { create(:tag, user: user, name: 'ヒアルロン酸') }

    let!(:record1) do
      create(:medical_record,
             user: user,
             patient: patient_a,
             facility: facility_a,
             visit_date: Date.new(2025, 1, 10),
             chief_complaint: '額のしわが気になる',
             tags: [tag_a])
    end

    let!(:record2) do
      create(:medical_record,
             user: user,
             patient: patient_b,
             facility: facility_b,
             visit_date: Date.new(2025, 2, 15),
             chief_complaint: 'ほうれい線の改善',
             tags: [tag_b])
    end

    let!(:record3) do
      create(:medical_record,
             user: user,
             patient: patient_a,
             facility: facility_a,
             visit_date: Date.new(2025, 3, 20),
             chief_complaint: '目元のたるみ',
             tags: [tag_a, tag_b])
    end

    describe '患者名で検索' do
      it '患者名の部分一致で検索できる' do
        get medical_records_path, params: { q: { patient_name_cont: '山田' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('額のしわが気になる')
        expect(response.body).to include('目元のたるみ')
        expect(response.body).not_to include('ほうれい線の改善')
      end
    end

    describe '施設で検索' do
      it '施設IDで検索できる' do
        get medical_records_path, params: { q: { facility_id_eq: facility_a.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('額のしわが気になる')
        expect(response.body).to include('目元のたるみ')
        expect(response.body).not_to include('ほうれい線の改善')
      end
    end

    describe '日付範囲で検索' do
      it '来院日の範囲で検索できる' do
        get medical_records_path, params: {
          q: {
            visit_date_gteq: Date.new(2025, 2, 1),
            visit_date_lteq: Date.new(2025, 2, 28),
          },
        }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('ほうれい線の改善')
        expect(response.body).not_to include('額のしわが気になる')
        expect(response.body).not_to include('目元のたるみ')
      end
    end

    describe 'タグで検索' do
      it 'タグIDで検索できる' do
        get medical_records_path, params: { q: { tags_id_eq: tag_a.id } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('額のしわが気になる')
        expect(response.body).to include('目元のたるみ')
        expect(response.body).not_to include('ほうれい線の改善')
      end
    end

    describe '主訴・診断・施術内容で検索' do
      it '主訴のキーワードで検索できる' do
        get medical_records_path, params: { q: { chief_complaint_cont: 'しわ' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('額のしわが気になる')
        expect(response.body).not_to include('ほうれい線の改善')
        expect(response.body).not_to include('目元のたるみ')
      end
    end

    describe '複合検索' do
      it '複数の条件を組み合わせて検索できる' do
        get medical_records_path, params: {
          q: {
            patient_name_cont: '山田',
            facility_id_eq: facility_a.id,
            tags_id_eq: tag_a.id,
          },
        }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('額のしわが気になる')
        expect(response.body).to include('目元のたるみ')
        expect(response.body).not_to include('ほうれい線の改善')
      end
    end

    describe 'ソート機能' do
      it '来院日の昇順でソートできる' do
        get medical_records_path, params: { q: { s: 'visit_date asc' } }
        expect(response).to have_http_status(:success)
        # 最初のカルテが record1 (2025-01-10) であることを確認
        body = response.body
        index1 = body.index('額のしわが気になる')
        index2 = body.index('ほうれい線の改善')
        index3 = body.index('目元のたるみ')
        expect(index1).to be < index2
        expect(index2).to be < index3
      end

      it '来院日の降順でソートできる' do
        get medical_records_path, params: { q: { s: 'visit_date desc' } }
        expect(response).to have_http_status(:success)
        # 最初のカルテが record3 (2025-03-20) であることを確認
        body = response.body
        index1 = body.index('額のしわが気になる')
        index2 = body.index('ほうれい線の改善')
        index3 = body.index('目元のたるみ')
        expect(index3).to be < index2
        expect(index2).to be < index1
      end
    end

    describe '他のユーザーのデータは検索されない' do
      let(:other_user) { create(:user) }
      let(:other_patient) { create(:patient, user: other_user, name: '鈴木一郎') }
      let(:other_facility) { create(:facility, user: other_user, name: '福岡院') }
      let!(:other_record) do
        create(:medical_record,
               user: other_user,
               patient: other_patient,
               facility: other_facility,
               chief_complaint: '他のユーザーのカルテ')
      end

      it '他のユーザーのカルテは検索結果に含まれない' do
        get medical_records_path, params: { q: { chief_complaint_cont: 'カルテ' } }
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('他のユーザーのカルテ')
      end
    end
  end
end
