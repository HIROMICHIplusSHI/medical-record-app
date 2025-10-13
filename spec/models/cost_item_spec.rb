require 'rails_helper'

RSpec.describe CostItem, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:medical_record) }
  end

  describe 'バリデーション' do
    subject { build(:cost_item) }

    it { is_expected.to validate_presence_of(:item_name) }
    it { is_expected.to validate_length_of(:item_name).is_at_most(200) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it do
      is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0)
    end

    # total_priceはコールバックで自動計算されるためバリデーションテストは省略
  end

  describe 'コールバック' do
    describe '#calculate_total_price' do
      it '保存前に合計金額を自動計算する' do
        cost_item = build(:cost_item, quantity: 2, unit_price: 30_000, total_price: nil)
        cost_item.valid?
        expect(cost_item.total_price).to eq(60_000)
      end

      it '数量または単価がnilの場合はバリデーションエラーになる' do
        cost_item = build(:cost_item, quantity: nil, unit_price: 30_000)
        expect(cost_item.valid?).to be false
        expect(cost_item.errors[:quantity]).to be_present
      end

      it '数量が変更されたら合計金額を再計算する' do
        cost_item = create(:cost_item, quantity: 1, unit_price: 50_000)
        cost_item.quantity = 3
        cost_item.valid?
        expect(cost_item.total_price).to eq(150_000)
      end

      it '単価が変更されたら合計金額を再計算する' do
        cost_item = create(:cost_item, quantity: 2, unit_price: 50_000)
        cost_item.unit_price = 40_000
        cost_item.valid?
        expect(cost_item.total_price).to eq(80_000)
      end
    end
  end
end
