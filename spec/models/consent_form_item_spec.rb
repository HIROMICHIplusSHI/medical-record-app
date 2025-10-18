require 'rails_helper'

RSpec.describe ConsentFormItem, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:consent_form_template) }
    it { is_expected.to have_many(:consent_item_responses).dependent(:destroy) }
  end

  describe 'バリデーション' do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).only_integer }
  end

  describe 'デフォルトスコープ' do
    it 'positionの昇順で取得される' do
      template = create(:consent_form_template)
      item3 = create(:consent_form_item, consent_form_template: template, position: 3)
      item1 = create(:consent_form_item, consent_form_template: template, position: 1)
      item2 = create(:consent_form_item, consent_form_template: template, position: 2)

      expect(template.consent_form_items).to eq([item1, item2, item3])
    end
  end

  describe '必須項目フラグ' do
    it 'デフォルトでis_requiredがtrueになる' do
      item = build(:consent_form_item)
      expect(item.is_required).to be true
    end

    it 'is_requiredをfalseに設定できる' do
      item = build(:consent_form_item, :optional)
      expect(item.is_required).to be false
    end
  end
end
