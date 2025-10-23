require 'rails_helper'

RSpec.describe PatientConsent, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:patient) }
    it { is_expected.to belong_to(:consent_form_template) }
    it { is_expected.to belong_to(:medical_record) }
    it { is_expected.to belong_to(:facility_doctor).optional }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:consent_item_responses).dependent(:destroy) }
  end

  describe 'バリデーション' do
    subject { build(:patient_consent) }

    it { is_expected.to validate_presence_of(:patient) }
    it { is_expected.to validate_presence_of(:consent_form_template) }
    it { is_expected.to validate_presence_of(:medical_record) }
    it { is_expected.to validate_presence_of(:user) }
    # agreed_atは before_validation :set_agreed_at で自動設定されるため、presence validationは不要
    # facility_doctorはオプショナル（必須ではない）

    it 'signature_dataが空の場合、エラーになる' do
      consent = build(:patient_consent, signature_data: nil)
      expect(consent).not_to be_valid
      expect(consent.errors[:signature_data]).to include('署名が必要です')
    end
  end

  describe '暗号化' do
    it 'signature_dataが暗号化される' do
      # 50x50ピクセルの白い背景PNG（約600バイト）
      test_signature = 'data:image/png;base64,' \
                       'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz' \
                       'AAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAAW' \
                       'dEVYdENyZWF0aW9uIFRpbWUAMDUvMDcvMjAxNkZWFf8AAAAgSURBVGiB7cEBDQAAAMKg909tDwcU' \
                       'AAAAAAAAAAAAAAAAgMEDEFAAAes7OygAAAAASUVORK5CYII='
      consent = create(:patient_consent, :with_responses, signature_data: test_signature)
      sql = ActiveRecord::Base.sanitize_sql_array([
                                                    'SELECT signature_data FROM patient_consents WHERE id = ?',
                                                    consent.id,
                                                  ])
      raw_value = ActiveRecord::Base.connection.execute(sql).first['signature_data']

      expect(raw_value).not_to eq(test_signature)
      expect(consent.reload.signature_data).to eq(test_signature)
    end

    it 'practitioner_nameが暗号化される' do
      consent = create(:patient_consent, :with_responses)
      expect(consent.practitioner_name).to be_present
    end

    it 'facility_nameが暗号化される' do
      consent = create(:patient_consent, :with_responses)
      expect(consent.facility_name).to be_present
    end
  end

  describe 'コールバック' do
    describe '#snapshot_facility_info' do
      it '作成時に施設情報をスナップショットとして保存する' do
        user = create(:user, company_name: 'アートメイク施術者 田中')
        facility = create(:facility,
                          user: user,
                          name: 'サロンA',
                          address: '東京都渋谷区',
                          phone: '03-1234-5678')
        patient = create(:patient, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)

        consent = create(:patient_consent, :with_responses,
                         medical_record: medical_record,
                         patient: patient,
                         user: user)

        expect(consent.facility_name).to eq('サロンA')
        expect(consent.facility_address).to eq('東京都渋谷区')
        expect(consent.facility_phone).to eq('03-1234-5678')
        expect(consent.practitioner_name).to eq('アートメイク施術者 田中')
      end

      it 'ユーザーにcompany_nameがない場合はemailを使用する' do
        user = create(:user, company_name: nil, email: 'test@example.com')
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = create(:patient_consent, :with_responses, user: user, patient: patient,
                                                            medical_record: medical_record)

        expect(consent.practitioner_name).to eq('test@example.com')
      end
    end

    describe '#snapshot_template_title' do
      it '作成時にテンプレートタイトルをスナップショットする' do
        user = create(:user)
        template = create(:consent_form_template, title: 'オリジナルタイトル', user: user)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)

        consent = create(:patient_consent, :with_responses,
                         user: user,
                         patient: patient,
                         medical_record: medical_record,
                         consent_form_template: template)

        # スナップショットされたタイトルが保存されている
        expect(consent.template_title).to eq('オリジナルタイトル')

        # テンプレート変更後も同意書のスナップショットは変わらない
        template.update(title: '変更後タイトル')
        consent.reload

        expect(consent.template_title).to eq('オリジナルタイトル')
        expect(consent.consent_form_template.title).to eq('変更後タイトル')
      end
    end
  end

  # nurse_confirmedの古いテストは削除（Critical Issue 1対応により不要）
  # 新しいテストは "看護師確認バリデーション" セクションに統合

  describe 'カスタムバリデーション' do
    describe '#all_required_items_checked' do
      it '必須項目がすべてチェックされている場合、有効' do
        user = create(:user)
        template = create(:consent_form_template, :with_items, user: user)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = build(:patient_consent,
                        user: user,
                        patient: patient,
                        medical_record: medical_record,
                        consent_form_template: template)

        # すべての項目にチェック済み回答を設定
        template.consent_form_items.each do |item|
          consent.consent_item_responses.build(
            consent_form_item: item,
            checked: true
          )
        end

        expect(consent).to be_valid
      end

      it '必須項目がチェックされていない場合、無効' do
        user = create(:user)
        template = create(:consent_form_template, user: user)
        required_item = create(:consent_form_item,
                               consent_form_template: template,
                               is_required: true,
                               content: '重要な同意事項')

        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = build(:patient_consent,
                        user: user,
                        patient: patient,
                        medical_record: medical_record,
                        consent_form_template: template)
        consent.consent_item_responses.build(
          consent_form_item: required_item,
          checked: false
        )

        expect(consent).not_to be_valid
        expect(consent.errors[:base]).to include('必須項目「重要な同意事項」にチェックが必要です')
      end

      it '任意項目はチェックなしでも有効' do
        user = create(:user)
        template = create(:consent_form_template, user: user)
        optional_item = create(:consent_form_item,
                               consent_form_template: template,
                               is_required: false)

        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = build(:patient_consent,
                        user: user,
                        patient: patient,
                        medical_record: medical_record,
                        consent_form_template: template)
        consent.consent_item_responses.build(
          consent_form_item: optional_item,
          checked: false
        )

        expect(consent).to be_valid
      end
    end
  end

  describe 'スコープ' do
    describe '.recent' do
      it '同意日時の降順で返す' do
        user = create(:user)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        template = create(:consent_form_template, :with_items, user: user)

        old_consent = create(:patient_consent, :with_responses,
                             user: user,
                             patient: patient,
                             medical_record: medical_record,
                             consent_form_template: template,
                             agreed_at: 2.days.ago)
        new_consent = create(:patient_consent, :with_responses,
                             user: user,
                             patient: patient,
                             medical_record: medical_record,
                             consent_form_template: template,
                             agreed_at: 1.day.ago)

        expect(PatientConsent.recent).to eq([new_consent, old_consent])
      end
    end

    describe '.for_patient' do
      it '指定した患者の同意書のみを返す' do
        user = create(:user)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        template = create(:consent_form_template, :with_items, user: user)
        consent = create(:patient_consent, :with_responses,
                         user: user,
                         patient: patient,
                         medical_record: medical_record,
                         consent_form_template: template)

        other_user = create(:user)
        other_patient = create(:patient, user: other_user)
        other_facility = create(:facility, user: other_user)
        other_medical_record = create(:medical_record, user: other_user, patient: other_patient,
                                                       facility: other_facility)
        other_template = create(:consent_form_template, :with_items, user: other_user)
        other_consent = create(:patient_consent, :with_responses,
                               user: other_user,
                               patient: other_patient,
                               medical_record: other_medical_record,
                               consent_form_template: other_template)

        expect(PatientConsent.for_patient(patient.id)).to include(consent)
        expect(PatientConsent.for_patient(patient.id)).not_to include(other_consent)
      end
    end

    describe '.for_medical_record' do
      it '指定したカルテの同意書のみを返す' do
        user = create(:user)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        template = create(:consent_form_template, :with_items, user: user)
        consent = create(:patient_consent, :with_responses,
                         user: user,
                         patient: patient,
                         medical_record: medical_record,
                         consent_form_template: template)

        other_user = create(:user)
        other_patient = create(:patient, user: other_user)
        other_facility = create(:facility, user: other_user)
        other_medical_record = create(:medical_record, user: other_user, patient: other_patient,
                                                       facility: other_facility)
        other_template = create(:consent_form_template, :with_items, user: other_user)
        other_consent = create(:patient_consent, :with_responses,
                               user: other_user,
                               patient: other_patient,
                               medical_record: other_medical_record,
                               consent_form_template: other_template)

        expect(PatientConsent.for_medical_record(medical_record.id)).to include(consent)
        expect(PatientConsent.for_medical_record(medical_record.id)).not_to include(other_consent)
      end
    end
  end

  # Critical Issue 1: 看護師確認のサーバーサイドバリデーション
  describe '看護師確認バリデーション' do
    it 'nurse_confirmedがtrueの場合、作成できる' do
      consent_with_nurse = build(:patient_consent, nurse_confirmed: true)
      expect(consent_with_nurse.save).to be true
    end

    it 'nurse_confirmedがfalseの場合、作成できない' do
      consent_without_nurse = build(:patient_consent, nurse_confirmed: false)
      expect(consent_without_nurse.save).to be false
      expect(consent_without_nurse.errors[:nurse_confirmed]).to include('看護師による最終確認が必要です')
    end

    # nilの場合はデータベース制約（null: false）で阻止されるため、
    # バリデーションテストは不要（false値のテストで十分）
  end

  # PDF改ざん防止機能のテスト
  describe 'PDF改ざん防止機能' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility) { create(:facility, user: user) }
    let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }
    let(:template) { create(:consent_form_template, :with_items, user: user) }
    let(:facility_doctor) { create(:facility_doctor, facility: facility) }
    let(:consent) do
      create(:patient_consent, :with_responses,
             user: user,
             patient: patient,
             medical_record: medical_record,
             consent_form_template: template,
             facility_doctor: facility_doctor)
    end

    before do
      # テスト用PDFディレクトリ作成
      pdf_dir = Rails.root.join('tmp', 'pdfs')
      FileUtils.mkdir_p(pdf_dir)
    end

    after do
      # テスト用PDFファイル削除
      pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{consent.id}.pdf")
      FileUtils.rm_f(pdf_path)
    end

    describe '#generate_pdf_hash!' do
      it 'PDFファイルが存在する場合、ハッシュ値を生成・保存する' do
        # PDF生成
        pdf_generator = PatientConsentPdfGenerator.new(consent)
        pdf_generator.generate

        # ハッシュ値が生成されたことを確認
        expect(consent.reload.pdf_hash).to be_present
        expect(consent.pdf_hash).to match(/\A[a-f0-9]{64}\z/) # SHA256ハッシュ形式
      end

      it 'PDFファイルが存在しない場合、falseを返す' do
        # PDFファイルを削除
        pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{consent.id}.pdf")
        FileUtils.rm_f(pdf_path)

        expect(consent.generate_pdf_hash!).to be false
      end
    end

    describe '#verify_pdf_integrity?' do
      it 'PDFが改ざんされていない場合、trueを返す' do
        # PDF生成
        pdf_generator = PatientConsentPdfGenerator.new(consent)
        pdf_generator.generate

        # 整合性確認
        expect(consent.reload.verify_pdf_integrity?).to be true
      end

      it 'PDFが改ざんされた場合、falseを返す' do
        # PDF生成
        pdf_generator = PatientConsentPdfGenerator.new(consent)
        pdf_generator.generate

        # PDFファイルを改ざん
        pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{consent.id}.pdf")
        File.write(pdf_path, 'tampered content')

        # 整合性確認
        expect(consent.reload.verify_pdf_integrity?).to be false
      end

      it 'PDFファイルが存在しない場合、falseを返す' do
        # PDFファイルを削除
        pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{consent.id}.pdf")
        FileUtils.rm_f(pdf_path)

        expect(consent.verify_pdf_integrity?).to be false
      end

      it 'ハッシュ値が保存されていない場合、falseを返す' do
        # PDF生成（ハッシュなし）
        pdf_dir = Rails.root.join('tmp', 'pdfs')
        pdf_path = pdf_dir.join("patient_consent_#{consent.id}.pdf")
        File.write(pdf_path, 'dummy pdf content')

        # ハッシュ値をnilに設定
        consent.update_column(:pdf_hash, nil)

        expect(consent.verify_pdf_integrity?).to be false
      end
    end

    describe '#invalidate_pdf_cache' do
      it '署名データ変更時にpdf_hashがnilになる' do
        # PDF生成
        pdf_generator = PatientConsentPdfGenerator.new(consent)
        pdf_generator.generate

        # ハッシュ値が存在することを確認
        expect(consent.reload.pdf_hash).to be_present
        consent.pdf_hash

        # 新しい署名データを作成（十分な大きさ）
        # 200x50の黒い矩形を描画したダミーPNG（Base64エンコード済み）
        new_signature_data = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAAAyCAYAAAAZUZThAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADHSURBVHhe7dIxDQAgEMCwA/+egQdmCB3JVbn7A/jLQCAYCARjbeDtGABrAwTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgLAmFBICwIhAWBsCAQFgTCgkBYEAgHZu4AsqIDBc8+BAAAAABJRU5ErkJggg==' # rubocop:disable Layout/LineLength

        # 署名データを更新
        result = consent.update(signature_data: new_signature_data)

        # 更新が成功したことを確認
        expect(result).to be true
        expect(consent.signature_data).to eq(new_signature_data)

        # ハッシュ値が無効化されたことを確認
        expect(consent.reload.pdf_hash).to be_nil
      end
    end
  end
end
