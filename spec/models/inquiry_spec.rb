require 'rails_helper'

RSpec.describe Inquiry, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:inquiry_messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:subject) }
    it { should validate_length_of(:subject).is_at_most(100) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it {
      should define_enum_for(:status).with_values(open: 0, in_progress: 1, closed: 2).backed_by_column_of_type(:integer)
    }
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.recent' do
      let!(:old_inquiry) { create(:inquiry, user: user, updated_at: 2.days.ago) }
      let!(:new_inquiry) { create(:inquiry, user: user, updated_at: 1.day.ago) }

      it '更新日時の降順で取得できる' do
        expect(Inquiry.recent).to eq([new_inquiry, old_inquiry])
      end
    end

    describe '.by_status' do
      let!(:open_inquiry) { create(:inquiry, user: user, status: :open) }
      let!(:closed_inquiry) { create(:inquiry, user: user, status: :closed) }

      it '指定したステータスのみ取得できる' do
        expect(Inquiry.by_status(:open)).to contain_exactly(open_inquiry)
      end

      it 'ステータスがnilの場合は全て取得できる' do
        expect(Inquiry.by_status(nil).count).to eq(2)
      end
    end
  end

  describe '#status_i18n' do
    it 'openの場合、"未対応"を返す' do
      inquiry = build(:inquiry, status: :open)
      expect(inquiry.status_i18n).to eq('未対応')
    end

    it 'in_progressの場合、"対応中"を返す' do
      inquiry = build(:inquiry, status: :in_progress)
      expect(inquiry.status_i18n).to eq('対応中')
    end

    it 'closedの場合、"対応完了"を返す' do
      inquiry = build(:inquiry, status: :closed)
      expect(inquiry.status_i18n).to eq('対応完了')
    end
  end
end
