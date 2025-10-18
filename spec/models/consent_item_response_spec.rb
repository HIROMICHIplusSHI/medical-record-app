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
        consent = create(:patient_consent)
        item = create(:consent_form_item)
        create(:consent_item_response, patient_consent: consent, consent_form_item: item)

        duplicate_response = build(:consent_item_response,
                                   patient_consent: consent,
                                   consent_form_item: item)

        expect(duplicate_response).not_to be_valid
        expect(duplicate_response.errors[:consent_form_item_id]).to include('同じ項目への回答がすでに存在します')
      end

      it '異なる同意書であれば同じ項目への回答でも許可される' do
        item = create(:consent_form_item)
        consent1 = create(:patient_consent)
        consent2 = create(:patient_consent)

        create(:consent_item_response, patient_consent: consent1, consent_form_item: item)
        duplicate_response = build(:consent_item_response,
                                   patient_consent: consent2,
                                   consent_form_item: item)

        expect(duplicate_response).to be_valid
      end
    end
  end

  describe 'デフォルト値' do
    it 'checkedのデフォルト値はfalse' do
      response = ConsentItemResponse.new
      expect(response.checked).to be false
    end
  end
end
