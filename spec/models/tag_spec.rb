require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should have_many(:medical_record_tags).dependent(:destroy) }
    it { should have_many(:medical_records).through(:medical_record_tags) }
  end

  describe 'バリデーション' do
    let(:user) { create(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }

    describe 'name uniqueness' do
      it 'ユーザーごとにタグ名が一意である' do
        user1 = create(:user)
        user2 = create(:user)

        create(:tag, user: user1, name: 'テストタグ')
        tag2 = build(:tag, user: user1, name: 'テストタグ')

        expect(tag2).not_to be_valid
        expect(tag2.errors[:name]).to be_present

        # 別ユーザーなら同じ名前でも可能
        tag3 = build(:tag, user: user2, name: 'テストタグ')
        expect(tag3).to be_valid
      end
    end

    describe 'color' do
      it '正しいHex形式は有効' do
        valid_colors = ['#FF0000', '#00ff00', '#0000FF', '#abcdef', '#ABCDEF']
        valid_colors.each do |color|
          tag = build(:tag, user: user, color: color)
          expect(tag).to be_valid
        end
      end

      it '不正な形式は無効' do
        invalid_colors = ['FF0000', '#FFF', 'red', '#GGGGGG']
        invalid_colors.each do |color|
          tag = build(:tag, user: user, color: color)
          expect(tag).not_to be_valid
          expect(tag.errors[:color]).to include('はHex形式で入力してください')
        end
      end

      it '空白は有効' do
        tag = build(:tag, user: user, color: nil)
        expect(tag).to be_valid
      end
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }

    describe '.by_name' do
      it '名前順で返す' do
        tag_c = create(:tag, user: user, name: 'Cタグ')
        tag_a = create(:tag, user: user, name: 'Aタグ')
        tag_b = create(:tag, user: user, name: 'Bタグ')

        expect(user.tags.by_name).to eq([tag_a, tag_b, tag_c])
      end
    end

    describe '.by_category' do
      let!(:tag1) { create(:tag, user: user, name: 'タグ1', category: '施術') }
      let!(:tag2) { create(:tag, user: user, name: 'タグ2', category: '症状') }
      let!(:tag3) { create(:tag, user: user, name: 'タグ3', category: '施術') }

      it 'カテゴリで絞り込める' do
        result = user.tags.by_category('施術')
        expect(result).to match_array([tag1, tag3])
      end

      it 'カテゴリが空の場合は全て返す' do
        result = user.tags.by_category('')
        expect(result).to match_array([tag1, tag2, tag3])
      end
    end
  end
end
