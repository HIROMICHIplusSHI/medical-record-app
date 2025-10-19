require 'rails_helper'

RSpec.describe ConsentFormItem, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:consent_form_template) }
    it { is_expected.to have_many(:consent_item_responses).dependent(:destroy) }
  end

  describe 'バリデーション' do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_numericality_of(:position).only_integer.allow_nil }
  end

  describe 'positionの自動設定' do
    let(:template) { create(:consent_form_template) }

    it 'positionが空の場合、自動的に1が設定される' do
      item = create(:consent_form_item, consent_form_template: template, position: nil)
      expect(item.position).to eq(1)
    end

    it '既存項目がある場合、最大値+1が設定される' do
      create(:consent_form_item, consent_form_template: template, position: 1)
      create(:consent_form_item, consent_form_template: template, position: 2)

      new_item = create(:consent_form_item, consent_form_template: template, position: nil)
      expect(new_item.position).to eq(3)
    end

    it 'positionが明示的に指定された場合は、その値を使用する' do
      item = create(:consent_form_item, consent_form_template: template, position: 5)
      expect(item.position).to eq(5)
    end
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
