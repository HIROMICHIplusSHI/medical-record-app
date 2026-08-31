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
      create(:medical_record, user: user, patient: patient, facility: facility, treatment_content: '主訴A')
      create(:medical_record, user: user, patient: patient, facility: facility, treatment_content: '主訴B')
      get medical_records_path
      expect(response.body).to include('主訴A')
      expect(response.body).to include('主訴B')
    end
  end

  describe 'GET /patients/:patient_id/medical_records（患者ごとの施術履歴）' do
    it '正常にレスポンスを返す' do
      get patient_medical_records_path(patient)
      expect(response).to have_http_status(:success)
    end

    # 杭: 患者スコープの一覧に他患者の施術記録が混ざらない
    it 'その患者の施術記録のみを表示する' do
      create(:medical_record, user: user, patient: patient, facility: facility, treatment_content: '対象患者の施術内容')
      another_patient = create(:patient, user: user, name: '別患者')
      create(:medical_record, user: user, patient: another_patient, facility: facility,
                              treatment_content: '別患者の施術内容')

      get patient_medical_records_path(patient)

      expect(response.body).to include('対象患者の施術内容')
      expect(response.body).not_to include('別患者の施術内容')
    end

    # 杭: patient_id を外部から受け取っても他ユーザーのデータには到達できない
    it '他のユーザーの患者の施術履歴にはアクセスできない' do
      foreign_user = create(:user)
      foreign_patient = create(:patient, user: foreign_user)

      get patient_medical_records_path(foreign_patient)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /patients/:patient_id/medical_records/new（患者を指定した新規作成）' do
    let(:named_patient) { create(:patient, user: user, name: '田中花子') }

    it '患者が選択済みの状態でフォームを表示する' do
      get new_patient_medical_record_path(named_patient)

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/<option[^>]*selected[^>]*value="#{named_patient.id}"[^>]*>/)
    end

    # 杭: 他ユーザーの患者を指定した施術記録の作成経路を作らない
    it '他のユーザーの患者を指定して新規作成できない' do
      foreign_user = create(:user)
      foreign_patient = create(:patient, user: foreign_user)

      get new_patient_medical_record_path(foreign_patient)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'パンくず（現在地の階層）' do
    let(:named_patient) { create(:patient, user: user, name: '佐藤次郎') }
    let(:record) do
      create(:medical_record, user: user, patient: named_patient, facility: facility,
                              visit_date: Date.new(2026, 5, 20))
    end

    # 杭: 階層は「レコードが属する患者」から導かれる。
    #     URL は /medical_records/:id で患者の文脈を持たないため、
    #     クエリパラメータやセッションに頼らず辿れることを固定する。
    it '施術記録詳細に患者起点の階層が出る' do
      get medical_record_path(record)

      expect(response.body).to include('aria-label="パンくず"')
      expect(response.body).to include(patients_path)
      expect(response.body).to include(patient_path(named_patient))
      expect(response.body).to include(patient_medical_records_path(named_patient))
      expect(response.body).to include('佐藤次郎')
    end

    it '編集画面では施術記録自体がリンクになり現在地が編集になる' do
      get edit_medical_record_path(record)

      expect(response.body).to include(medical_record_path(record))
      expect(response.body).to include('aria-current="page"')
    end

    it '患者スコープの施術履歴では患者がリンクになる' do
      get patient_medical_records_path(named_patient)

      expect(response.body).to include(patient_path(named_patient))
      expect(response.body).to include('aria-label="パンくず"')
    end

    it '全体の施術履歴一覧にはパンくずを出さない' do
      get medical_records_path

      expect(response.body).not_to include('aria-label="パンくず"')
    end
  end

  describe '施術履歴一覧の既定の並び順' do
    it '指定が無ければ来院日の新しい順になる（患者詳細の並びと一致する）' do
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2020, 1, 1), treatment_content: '古い記録')
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2026, 1, 1), treatment_content: '新しい記録')

      get medical_records_path

      expect(response.body.index('新しい記録')).to be < response.body.index('古い記録')
    end

    it '患者スコープの一覧でも同じ並び順になる' do
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2020, 1, 1), treatment_content: '古い記録')
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2026, 1, 1), treatment_content: '新しい記録')

      get patient_medical_records_path(patient)

      expect(response.body.index('新しい記録')).to be < response.body.index('古い記録')
    end
  end

  describe 'パンくずの構造（DOM で検証）' do
    let(:named_patient) { create(:patient, user: user, name: '構造検証患者') }
    let(:record) do
      create(:medical_record, user: user, patient: named_patient, facility: facility,
                              visit_date: Date.new(2026, 5, 20))
    end

    def breadcrumb_links(body)
      doc = Nokogiri::HTML(body)
      nav = doc.at('nav[aria-label="パンくず"]')
      return [] if nav.nil?

      nav.css('a').map { |a| [a.text.strip, a['href']] }
    end

    # 部分文字列一致では上位パスが下位パスに含まれてしまうため、
    # パンくず領域内のリンクを順序込みで検証する
    it '施術記録詳細のパンくずが順序どおりのリンクを持つ' do
      get medical_record_path(record)

      expect(breadcrumb_links(response.body)).to eq([
                                                      ['患者', patients_path],
                                                      ['構造検証患者', patient_path(named_patient)],
                                                      ['施術履歴', patient_medical_records_path(named_patient)],
                                                    ])
    end

    # 杭3の反証形: 文脈を外から与えても階層は変わらない
    it 'クエリパラメータで別患者を渡してもパンくずは変わらない' do
      other_patient = create(:patient, user: user, name: '別の患者')

      get medical_record_path(record, patient_id: other_patient.id)

      links = breadcrumb_links(response.body)
      expect(links.map(&:first)).to include('構造検証患者')
      expect(links.map(&:first)).not_to include('別の患者')
    end
  end

  describe '患者を指定した作成に失敗したとき' do
    it '患者の文脈（パンくず・戻り先）が保たれる' do
      post medical_records_path, params: {
        medical_record: { patient_id: patient.id, facility_id: facility.id, visit_date: '', treatment_content: '' },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(patient_path(patient))
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
            treatment_content: 'ボトックス注射を実施',
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
            treatment_content: '更新された施術内容',
          },
        }
      end

      it 'カルテが更新される' do
        patch medical_record_path(medical_record), params: update_params
        medical_record.reload
        expect(medical_record.treatment_content).to eq('更新された施術内容')
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
            treatment_content: '',
          },
        }
      end

      it 'カルテが更新されない' do
        original_content = medical_record.treatment_content
        patch medical_record_path(medical_record), params: invalid_params
        medical_record.reload
        expect(medical_record.treatment_content).to eq(original_content)
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
      original_content = other_record.treatment_content
      patch medical_record_path(other_record), params: { medical_record: { treatment_content: 'hacked' } }
      expect(response).to have_http_status(:not_found)
      expect(other_record.reload.treatment_content).to eq(original_content)
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
             treatment_content: '額のしわが気になる',
             tags: [tag_a])
    end

    let!(:record2) do
      create(:medical_record,
             user: user,
             patient: patient_b,
             facility: facility_b,
             visit_date: Date.new(2025, 2, 15),
             treatment_content: 'ほうれい線の改善',
             tags: [tag_b])
    end

    let!(:record3) do
      create(:medical_record,
             user: user,
             patient: patient_a,
             facility: facility_a,
             visit_date: Date.new(2025, 3, 20),
             treatment_content: '目元のたるみ',
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

    describe '施術内容で検索' do
      it '施術内容のキーワードで検索できる' do
        get medical_records_path, params: { q: { treatment_content_cont: 'しわ' } }
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
               treatment_content: '他のユーザーのカルテ')
      end

      it '他のユーザーのカルテは検索結果に含まれない' do
        get medical_records_path, params: { q: { treatment_content_cont: 'カルテ' } }
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('他のユーザーのカルテ')
      end
    end
  end

  describe 'カルテ詳細ページの問診票セクション' do
    context '問診票が存在する場合' do
      let!(:questionnaire) { create(:questionnaire, patient: patient) }

      it '問診票確認ボタンが表示される' do
        get medical_record_path(medical_record)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('問診票を確認')
        expect(response.body).not_to include('問診票を作成')
      end

      it '問診票確認ボタンにfrom_medical_record_idパラメータが含まれる' do
        get medical_record_path(medical_record)
        expect(response.body).to include("from_medical_record_id=#{medical_record.id}")
      end

      it '問診票の更新日が表示される' do
        get medical_record_path(medical_record)
        expect(response.body).to include('問診票が登録されています')
      end
    end

    context '問診票が存在しない場合' do
      it '問診票作成ボタンが表示される' do
        get medical_record_path(medical_record)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('問診票を作成')
        expect(response.body).not_to include('問診票を確認')
      end

      it '問診票作成ボタンにfrom_medical_record_idパラメータが含まれる' do
        get medical_record_path(medical_record)
        expect(response.body).to include("from_medical_record_id=#{medical_record.id}")
      end

      it '問診票未作成のメッセージが表示される' do
        get medical_record_path(medical_record)
        expect(response.body).to include('問診票はまだ作成されていません')
      end
    end
  end
end
