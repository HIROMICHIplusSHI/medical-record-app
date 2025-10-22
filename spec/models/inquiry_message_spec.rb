require 'rails_helper'

RSpec.describe InquiryMessage, type: :model do
  describe 'associations' do
    it { should belong_to(:inquiry) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_most(2000) }
  end

  describe 'touch inquiry' do
    let(:user) { create(:user) }
    let(:inquiry) { create(:inquiry, user: user) }

    it 'メッセージ作成時にinquiryのupdated_atが更新される' do
      expect do
        create(:inquiry_message, inquiry: inquiry, user: user)
      end.to(change { inquiry.reload.updated_at })
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:inquiry) { create(:inquiry, user: user) }
    let!(:old_message) do
      create(:inquiry_message, inquiry: inquiry, user: user, created_at: 2.hours.ago)
    end
    let!(:new_message) do
      create(:inquiry_message, inquiry: inquiry, user: user, created_at: 1.hour.ago)
    end

    describe '.chronological' do
      it '作成日時の昇順で取得できる' do
        expect(inquiry.inquiry_messages.chronological).to eq([old_message, new_message])
      end
    end
  end
end
