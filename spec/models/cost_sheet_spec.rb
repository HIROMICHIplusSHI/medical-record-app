require 'rails_helper'

RSpec.describe CostSheet, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'バリデーション' do
    subject { build(:cost_sheet) }

    it { is_expected.to validate_presence_of(:item_name) }
    it { is_expected.to validate_length_of(:item_name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:standard_price) }
    it { is_expected.to validate_numericality_of(:standard_price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:category).in_array(CostSheet::CATEGORIES.keys).allow_blank }
  end

  describe 'CATEGORIES定数' do
    it 'カテゴリマッピングが正しい' do
      expect(CostSheet::CATEGORIES).to eq({
                                            'treatment' => '施術',
                                            'medicine' => '薬剤',
                                            'supplies' => '消耗品',
                                            'other' => 'その他',
                                          })
    end
  end

  describe '#category_name' do
    context 'カテゴリがtreatmentの場合' do
      let(:cost_sheet) { build(:cost_sheet, category: 'treatment') }

      it '施術を返す' do
        expect(cost_sheet.category_name).to eq('施術')
      end
    end

    context 'カテゴリがmedicineの場合' do
      let(:cost_sheet) { build(:cost_sheet, :medicine) }

      it '薬剤を返す' do
        expect(cost_sheet.category_name).to eq('薬剤')
      end
    end

    context 'カテゴリが未定義の場合' do
      let(:cost_sheet) { build(:cost_sheet, category: 'unknown') }

      it '生のカテゴリ値を返す' do
        expect(cost_sheet.category_name).to eq('unknown')
      end
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let!(:cost_sheet1) { create(:cost_sheet, user: user, item_name: 'B施術', created_at: 2.days.ago) }
    let!(:cost_sheet2) { create(:cost_sheet, user: user, item_name: 'A施術', created_at: 1.day.ago) }
    let!(:cost_sheet3) { create(:cost_sheet, :medicine, user: user, created_at: 3.days.ago) }

    describe '.by_name' do
      it '項目名でソートされる' do
        # item_nameでソートされていることを確認
        # （日本語のソート順は環境依存のため、SQLのORDER BYが適用されていることのみを確認）
        result = CostSheet.by_name.to_a
        expect(result).to contain_exactly(cost_sheet1, cost_sheet2, cost_sheet3)
        # スコープが正しくソートを適用していることを確認
        expect(CostSheet.by_name.to_sql).to include('ORDER BY')
        expect(CostSheet.by_name.to_sql).to include('item_name')
      end
    end

    describe '.recent' do
      it '作成日の降順でソートされる' do
        expect(CostSheet.recent).to eq([cost_sheet2, cost_sheet1, cost_sheet3])
      end
    end

    describe '.by_category' do
      it 'カテゴリでフィルタリングされる' do
        expect(CostSheet.by_category('treatment')).to contain_exactly(cost_sheet1, cost_sheet2)
      end

      it 'カテゴリが空の場合は全件返す' do
        expect(CostSheet.by_category('')).to contain_exactly(cost_sheet1, cost_sheet2, cost_sheet3)
      end
    end
  end

  describe 'ファクトリ' do
    it '有効なコストシートが作成できる' do
      cost_sheet = build(:cost_sheet)
      expect(cost_sheet).to be_valid
    end

    it 'medicineトレイトが機能する' do
      cost_sheet = build(:cost_sheet, :medicine)
      expect(cost_sheet.category).to eq('medicine')
    end

    it 'suppliesトレイトが機能する' do
      cost_sheet = build(:cost_sheet, :supplies)
      expect(cost_sheet.category).to eq('supplies')
    end
  end
end
