require 'rails_helper'

RSpec.describe 'PatientConsents', type: :request do
  let(:user) { create(:user) }
  let(:facility) { create(:facility, user: user) }
  let(:patient) { create(:patient, user: user) }
  let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }
  let(:consent_template) { create(:consent_form_template, user: user) }
  let!(:facility_doctor) { create(:facility_doctor, facility: facility) }

  before do
    sign_in user
    # テンプレートにチェック項目を追加
    create(:consent_form_item, consent_form_template: consent_template, position: 1, is_required: true)
    create(:consent_form_item, consent_form_template: consent_template, position: 2, is_required: false)
  end

  describe 'GET /medical_records/:medical_record_id/patient_consents/new' do
    it '同意書作成画面が表示される' do
      get new_medical_record_patient_consent_path(medical_record)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('同意書作成')
      expect(response.body).to include(consent_template.title)
      expect(response.body).to include(facility_doctor.name)
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        get new_medical_record_patient_consent_path(medical_record)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '他のユーザーのカルテの場合' do
      let!(:other_user) { create(:user) }
      let!(:other_facility) { create(:facility, user: other_user) }
      let!(:other_patient) { create(:patient, user: other_user) }
      let!(:other_medical_record) do
        create(:medical_record, user: other_user, patient: other_patient, facility: other_facility)
      end

      it '404エラーが返される' do
        get new_medical_record_patient_consent_path(other_medical_record)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /medical_records/:medical_record_id/patient_consents' do
    let(:valid_signature) do
      # 50x50ピクセルの白い背景PNG（約600バイト、署名データバリデーション対応）
      'data:image/png;base64,' \
        'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz' \
        'AAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAAW' \
        'dEVYdENyZWF0aW9uIFRpbWUAMDUvMDcvMjAxNkZWFf8AAAAgSURBVGiB7cEBDQAAAMKg909tDwcU' \
        'AAAAAAAAAAAAAAAAgMEDEFAAAes7OygAAAAASUVORK5CYII='
    end

    let(:valid_params) do
      {
        patient_consents: {
          '0' => {
            selected: '1',
            consent_form_template_id: consent_template.id,
            facility_doctor_id: facility_doctor.id,
            signature_data: valid_signature,
            consent_item_responses_attributes: {
              '0' => {
                consent_form_item_id: consent_template.consent_form_items.first.id,
                checked: '1',
              },
              '1' => {
                consent_form_item_id: consent_template.consent_form_items.second.id,
                checked: '1',
              },
            },
          },
        },
      }
    end

    context '有効なパラメータの場合' do
      it '同意書が作成される' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: valid_params
        end.to change(PatientConsent, :count).by(1)
      end

      it '同意書回答が作成される' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: valid_params
        end.to change(ConsentItemResponse, :count).by(2)
      end

      it 'カルテ詳細画面にリダイレクトされる' do
        post medical_record_patient_consents_path(medical_record), params: valid_params
        expect(response).to redirect_to(medical_record_path(medical_record))
      end

      it '成功メッセージが表示される' do
        post medical_record_patient_consents_path(medical_record), params: valid_params
        expect(flash[:notice]).to eq('1件の同意書を作成しました。')
      end

      it '署名日時が自動設定される' do
        post medical_record_patient_consents_path(medical_record), params: valid_params
        consent = PatientConsent.last
        expect(consent.agreed_at).to be_present
        expect(consent.agreed_at).to be_within(2.seconds).of(Time.current)
      end

      it '施設情報がスナップショットとして保存される' do
        post medical_record_patient_consents_path(medical_record), params: valid_params
        consent = PatientConsent.last

        expect(consent.facility_name).to eq(facility.name)
        expect(consent.facility_address).to eq(facility.address)
        expect(consent.facility_phone).to eq(facility.phone)
      end
    end

    context '医師選択なしの場合' do
      let(:params_without_doctor) do
        valid_params.deep_dup.tap do |params|
          params[:patient_consents]['0'][:facility_doctor_id] = ''
        end
      end

      it '同意書が作成される' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: params_without_doctor
        end.to change(PatientConsent, :count).by(1)
      end

      it 'facility_doctorがnilで保存される' do
        post medical_record_patient_consents_path(medical_record), params: params_without_doctor
        consent = PatientConsent.last
        expect(consent.facility_doctor).to be_nil
      end

      it '成功メッセージが表示される' do
        post medical_record_patient_consents_path(medical_record), params: params_without_doctor
        expect(flash[:notice]).to eq('1件の同意書を作成しました。')
      end
    end

    context '複数の同意書を同時作成する場合' do
      let(:consent_template2) { create(:consent_form_template, user: user) }

      before do
        create(:consent_form_item, consent_form_template: consent_template2, position: 1, is_required: true)
      end

      let(:multiple_params) do
        {
          patient_consents: {
            '0' => {
              selected: '1',
              consent_form_template_id: consent_template.id,
              facility_doctor_id: facility_doctor.id,
              signature_data: valid_signature,
              consent_item_responses_attributes: {
                '0' => {
                  consent_form_item_id: consent_template.consent_form_items.first.id,
                  checked: '1',
                },
              },
            },
            '1' => {
              selected: '1',
              consent_form_template_id: consent_template2.id,
              facility_doctor_id: facility_doctor.id,
              signature_data: valid_signature,
              consent_item_responses_attributes: {
                '0' => {
                  consent_form_item_id: consent_template2.consent_form_items.first.id,
                  checked: '1',
                },
              },
            },
          },
        }
      end

      it '複数の同意書が作成される' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: multiple_params
        end.to change(PatientConsent, :count).by(2)
      end

      it '成功メッセージに件数が表示される' do
        post medical_record_patient_consents_path(medical_record), params: multiple_params
        expect(flash[:notice]).to eq('2件の同意書を作成しました。')
      end
    end

    context '署名データがない場合' do
      let(:invalid_params) do
        valid_params.deep_dup.tap do |params|
          params[:patient_consents]['0'][:signature_data] = ''
        end
      end

      it '同意書が作成されない' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: invalid_params
        end.not_to change(PatientConsent, :count)
      end

      it 'エラーメッセージが表示される' do
        post medical_record_patient_consents_path(medical_record), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '必須項目がチェックされていない場合' do
      let(:invalid_params) do
        valid_params.deep_dup.tap do |params|
          params[:patient_consents]['0'][:consent_item_responses_attributes]['0'][:checked] = '0'
        end
      end

      it '同意書が作成されない' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: invalid_params
        end.not_to change(PatientConsent, :count)
      end

      it 'エラーメッセージが表示される' do
        post medical_record_patient_consents_path(medical_record), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('必須項目')
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        post medical_record_patient_consents_path(medical_record), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it '同意書が作成されない' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: valid_params
        end.not_to change(PatientConsent, :count)
      end
    end

    context 'トランザクションのテスト' do
      let(:consent_template2) { create(:consent_form_template, user: user) }

      before do
        create(:consent_form_item, consent_form_template: consent_template2, position: 1, is_required: true)
      end

      let(:mixed_params) do
        {
          patient_consents: {
            '0' => {
              selected: '1',
              consent_form_template_id: consent_template.id,
              facility_doctor_id: facility_doctor.id,
              signature_data: valid_signature,
              consent_item_responses_attributes: {
                '0' => {
                  consent_form_item_id: consent_template.consent_form_items.first.id,
                  checked: '1',
                },
              },
            },
            '1' => {
              selected: '1',
              consent_form_template_id: consent_template2.id,
              facility_doctor_id: facility_doctor.id,
              signature_data: '', # 無効な署名データ
              consent_item_responses_attributes: {
                '0' => {
                  consent_form_item_id: consent_template2.consent_form_items.first.id,
                  checked: '1',
                },
              },
            },
          },
        }
      end

      it '一つでも失敗するとロールバックされる' do
        expect do
          post medical_record_patient_consents_path(medical_record), params: mixed_params
        end.not_to change(PatientConsent, :count)
      end
    end
  end

  describe 'GET /medical_records/:medical_record_id/patient_consents' do
    let!(:patient_consent1) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    let!(:patient_consent2) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template,
             agreed_at: 1.day.ago)
    end

    it '同意書一覧が表示される' do
      get medical_record_patient_consents_path(medical_record)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(consent_template.title)
    end

    it '新しい順に表示される' do
      get medical_record_patient_consents_path(medical_record)

      # レスポンスボディで順序を確認（新しい順）
      # patient_consent1が先に、patient_consent2が後に出現する
      pos1 = response.body.index("data-consent-id=\"#{patient_consent1.id}\"")
      pos2 = response.body.index("data-consent-id=\"#{patient_consent2.id}\"")

      expect(pos1).to be < pos2
    end
  end

  describe 'GET /medical_records/:medical_record_id/patient_consents/:id' do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    it '同意書詳細が表示される' do
      get medical_record_patient_consent_path(medical_record, patient_consent)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(consent_template.title)
      expect(response.body).to include(patient.name)
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        get medical_record_patient_consent_path(medical_record, patient_consent)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '他のユーザーの同意書の場合' do
      let!(:other_user) { create(:user) }
      let!(:other_facility) { create(:facility, user: other_user) }
      let!(:other_patient) { create(:patient, user: other_user) }
      let!(:other_medical_record) do
        create(:medical_record, user: other_user, patient: other_patient, facility: other_facility)
      end
      let!(:other_template) { create(:consent_form_template, user: other_user) }
      let!(:other_consent) do
        create(:patient_consent, :with_responses,
               medical_record: other_medical_record,
               patient: other_patient,
               user: other_user,
               consent_form_template: other_template)
      end

      it '404エラーが返される' do
        get medical_record_patient_consent_path(other_medical_record, other_consent)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /medical_records/:medical_record_id/patient_consents/:id/generate_pdf' do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    it 'PDFが生成される' do
      post generate_pdf_medical_record_patient_consent_path(medical_record, patient_consent)

      expect(response).to redirect_to(medical_record_patient_consent_path(medical_record, patient_consent))
      expect(flash[:notice]).to eq('PDFを生成しました。')

      # PDFファイルが作成されていることを確認
      pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{patient_consent.id}.pdf")
      expect(File.exist?(pdf_path)).to be true

      # クリーンアップ
      FileUtils.rm_f(pdf_path)
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        post generate_pdf_medical_record_patient_consent_path(medical_record, patient_consent)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /medical_records/:medical_record_id/patient_consents/:id/download_pdf' do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    before do
      # PDFを事前に生成
      generator = PatientConsentPdfGenerator.new(patient_consent)
      generator.generate
    end

    after do
      # クリーンアップ
      pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{patient_consent.id}.pdf")
      FileUtils.rm_f(pdf_path)
    end

    it 'PDFがダウンロードされる' do
      get download_pdf_medical_record_patient_consent_path(medical_record, patient_consent)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include("patient_consent_#{patient_consent.id}.pdf")
    end

    context 'PDFが生成されていない場合' do
      before do
        pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{patient_consent.id}.pdf")
        FileUtils.rm_f(pdf_path)
      end

      it 'エラーメッセージが表示される' do
        get download_pdf_medical_record_patient_consent_path(medical_record, patient_consent)

        expect(response).to redirect_to(medical_record_patient_consent_path(medical_record, patient_consent))
        expect(flash[:alert]).to eq('PDFが生成されていません。先にPDF生成を実行してください。')
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        get download_pdf_medical_record_patient_consent_path(medical_record, patient_consent)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /medical_records/:medical_record_id/patient_consents/:id/preview_pdf' do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    it 'PDFがプレビューされる' do
      get preview_pdf_medical_record_patient_consent_path(medical_record, patient_consent)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('inline')
      expect(response.headers['Content-Disposition']).to include("preview_patient_consent_#{patient_consent.id}.pdf")
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        get preview_pdf_medical_record_patient_consent_path(medical_record, patient_consent)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    it '同意書が削除される' do
      expect do
        delete medical_record_patient_consent_path(medical_record, patient_consent)
      end.to change(PatientConsent, :count).by(-1)
    end

    it 'カルテ詳細画面にリダイレクトされる' do
      delete medical_record_patient_consent_path(medical_record, patient_consent)
      expect(response).to redirect_to(medical_record_path(medical_record))
    end

    it '成功メッセージが表示される' do
      delete medical_record_patient_consent_path(medical_record, patient_consent)
      expect(flash[:notice]).to eq('同意書を削除しました。')
    end

    it '関連するPDFファイルが削除される' do
      # PDFを生成
      pdf_path = PatientConsentPdfGenerator.new(patient_consent).generate
      expect(File.exist?(pdf_path)).to be true

      # 同意書を削除
      delete medical_record_patient_consent_path(medical_record, patient_consent)

      # PDFファイルが削除されていることを確認
      expect(File.exist?(pdf_path)).to be false
    end

    context '他のユーザーの同意書' do
      let(:other_user) { create(:user) }
      let(:other_facility) { create(:facility, user: other_user) }
      let(:other_patient) { create(:patient, user: other_user) }
      let(:other_medical_record) do
        create(:medical_record, user: other_user, patient: other_patient, facility: other_facility)
      end
      let!(:other_consent) do
        create(:patient_consent, :with_responses, medical_record: other_medical_record, user: other_user)
      end

      it '削除できない（同意書が見つからない）' do
        # 他のユーザーのカルテにアクセスしようとすると RecordNotFound が発生
        initial_count = PatientConsent.count
        begin
          delete medical_record_patient_consent_path(other_medical_record, other_consent)
        rescue ActiveRecord::RecordNotFound
          # 期待される例外
        end
        expect(PatientConsent.count).to eq(initial_count)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        delete medical_record_patient_consent_path(medical_record, patient_consent)
        expect(response).to redirect_to(new_user_session_path)
      end

      it '同意書が削除されない' do
        expect do
          delete medical_record_patient_consent_path(medical_record, patient_consent)
        end.not_to change(PatientConsent, :count)
      end
    end
  end
end
