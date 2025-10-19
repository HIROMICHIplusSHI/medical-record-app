require 'rails_helper'

RSpec.describe ConsentItemResponse, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:patient_consent) }
    it { is_expected.to belong_to(:consent_form_item) }
  end

  describe 'バリデーション' do
    subject { build(:consent_item_response) }

    it { is_expected.to validate_presence_of(:patient_consent) }
    it { is_expected.to validate_presence_of(:consent_form_item) }

    it 'checkedフィールドはtrueまたはfalseのみ許可される' do
      response = build(:consent_item_response, checked: true)
      expect(response).to be_valid

      response.checked = false
      expect(response).to be_valid
    end

    context '同一同意書内での項目回答の一意性' do
      it '同じ同意書で同じ項目への回答が重複する場合、エラーになる' do
        user = create(:user)
        template = create(:consent_form_template, user: user)
        item = create(:consent_form_item, consent_form_template: template, is_required: true)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = build(:patient_consent,
                        user: user,
                        patient: patient,
                        medical_record: medical_record,
                        consent_form_template: template)
        consent.consent_item_responses.build(consent_form_item: item, checked: true)
        consent.save!

        duplicate_response = build(:consent_item_response,
                                   patient_consent: consent,
                                   consent_form_item: item)

        expect(duplicate_response).not_to be_valid
        expect(duplicate_response.errors[:consent_form_item_id]).to include('同じ項目への回答がすでに存在します')
      end

      it '異なる同意書であれば同じ項目への回答でも許可される' do
        user = create(:user)
        template = create(:consent_form_template, user: user)
        item = create(:consent_form_item, consent_form_template: template, is_required: true)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent1 = build(:patient_consent,
                         user: user,
                         patient: patient,
                         medical_record: medical_record,
                         consent_form_template: template)
        consent1.consent_item_responses.build(consent_form_item: item, checked: true)
        consent1.save!

        consent2 = build(:patient_consent,
                         user: user,
                         patient: patient,
                         medical_record: medical_record,
                         consent_form_template: template)

        # consent1の同じitemに対するresponseが既に存在するが、
        # 異なるconsent（consent2）であれば同じitemへのresponseを追加できる
        response_for_consent2 = consent2.consent_item_responses.build(
          consent_form_item: item,
          checked: true
        )

        expect(response_for_consent2).to be_valid
        expect(consent2.save).to be true
      end
    end
  end

  describe 'デフォルト値' do
    it 'checkedのデフォルト値はfalse' do
      response = ConsentItemResponse.new
      expect(response.checked).to be false
    end
  end

  describe 'コールバック' do
    describe '#snapshot_item_content' do
      it '作成時に同意項目内容をスナップショットする' do
        user = create(:user)
        template = create(:consent_form_template, user: user)
        item = create(:consent_form_item,
                      consent_form_template: template,
                      content: 'オリジナル内容',
                      is_required: true)
        patient = create(:patient, user: user)
        facility = create(:facility, user: user)
        medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
        consent = build(:patient_consent,
                        user: user,
                        patient: patient,
                        medical_record: medical_record,
                        consent_form_template: template)
        consent.consent_item_responses.build(consent_form_item: item, checked: true)
        consent.save!

        response = consent.consent_item_responses.first

        # スナップショットされた内容が保存されている
        expect(response.item_content).to eq('オリジナル内容')

        # 項目変更後もレスポンスのスナップショットは変わらない
        item.update(content: '変更後内容')
        response.reload

        expect(response.item_content).to eq('オリジナル内容')
        expect(response.consent_form_item.content).to eq('変更後内容')
      end
    end
  end
end
