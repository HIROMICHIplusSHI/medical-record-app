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

    it {
      should define_enum_for(:category).with_values(
        general: 0, bug_report: 1, feature_request: 2, other: 3
      ).backed_by_column_of_type(:integer)
    }

    it {
      should define_enum_for(:last_message_by).with_values(
        user: 0, admin: 1
      ).backed_by_column_of_type(:integer)
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

    describe '.by_category' do
      let!(:general_inquiry) { create(:inquiry, user: user, category: :general) }
      let!(:bug_inquiry) { create(:inquiry, user: user, category: :bug_report) }

      it '指定したカテゴリのみ取得できる' do
        expect(Inquiry.by_category(:general)).to contain_exactly(general_inquiry)
      end

      it 'カテゴリがnilの場合は全て取得できる' do
        expect(Inquiry.by_category(nil).count).to eq(2)
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

  describe '#category_i18n' do
    it 'generalの場合、"一般的な質問"を返す' do
      inquiry = build(:inquiry, category: :general)
      expect(inquiry.category_i18n).to eq('一般的な質問')
    end

    it 'bug_reportの場合、"不具合報告"を返す' do
      inquiry = build(:inquiry, category: :bug_report)
      expect(inquiry.category_i18n).to eq('不具合報告')
    end

    it 'feature_requestの場合、"機能要望"を返す' do
      inquiry = build(:inquiry, category: :feature_request)
      expect(inquiry.category_i18n).to eq('機能要望')
    end

    it 'otherの場合、"その他"を返す' do
      inquiry = build(:inquiry, category: :other)
      expect(inquiry.category_i18n).to eq('その他')
    end
  end

  describe 'cache invalidation' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, role: :admin) }
    let!(:inquiry) { create(:inquiry, user: user, status: :open) }

    context 'ステータス変更時' do
      it '管理者とユーザーのキャッシュがクリアされる' do
        # 管理者のキャッシュがクリアされることを確認（少なくとも1回）
        expect(Rails.cache).to receive(:delete).with("unread_inquiry_count_user_#{admin.id}").at_least(:once)
        # ユーザーのキャッシュがクリアされることを確認（少なくとも1回）
        expect(Rails.cache).to receive(:delete).with("unread_inquiry_count_user_#{user.id}").at_least(:once)

        inquiry.update(status: :in_progress)
      end
    end

    context 'last_message_by変更時' do
      it '管理者とユーザーのキャッシュがクリアされる' do
        expect(Rails.cache).to receive(:delete).with("unread_inquiry_count_user_#{admin.id}").at_least(:once)
        expect(Rails.cache).to receive(:delete).with("unread_inquiry_count_user_#{user.id}").at_least(:once)

        inquiry.update(last_message_by: :admin)
      end
    end

    context 'ステータス・last_message_by以外の変更時' do
      it 'キャッシュがクリアされない' do
        # ユーザーと管理者のキャッシュキーが呼ばれないことを確認
        expect(Rails.cache).not_to receive(:delete).with("unread_inquiry_count_user_#{admin.id}")
        expect(Rails.cache).not_to receive(:delete).with("unread_inquiry_count_user_#{user.id}")

        inquiry.update(subject: '新しい件名')
      end
    end
  end
end
