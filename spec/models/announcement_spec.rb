require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(1000) }

    describe 'published_at' do
      let(:admin) { create(:user, :admin) }

      it '公開中の場合はpublished_atが必須' do
        announcement = build(:announcement, author: admin, status: :published, published_at: nil)
        expect(announcement).not_to be_valid
        expect(announcement.errors[:published_at]).to be_present
      end

      it '下書きの場合はpublished_atは不要' do
        announcement = build(:announcement, author: admin, status: :draft, published_at: nil)
        expect(announcement).to be_valid
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, archived: 2).with_default(:draft) }
    it { is_expected.to define_enum_for(:severity).with_values(info: 0, warning: 1, critical: 2).with_default(:info) }
  end

  describe 'scopes' do
    let(:admin) { create(:user, :admin) }

    describe '.active' do
      it '公開中かつ有効期限内のお知らせのみを返す' do
        active1 = create(:announcement, :published, author: admin, published_at: 1.day.ago, expires_at: 1.day.from_now,
                                                    display_order: 1)
        active2 = create(:announcement, :published, author: admin, published_at: 2.days.ago, expires_at: nil,
                                                    display_order: 0)
        create(:announcement, :draft, author: admin) # 下書き
        create(:announcement, :published, author: admin, published_at: 1.day.from_now) # 未来の公開日
        create(:announcement, :published, author: admin, published_at: 2.days.ago, expires_at: 1.day.ago) # 期限切れ

        expect(Announcement.active).to contain_exactly(active1, active2)
      end

      it 'display_order昇順、published_at降順でソートされる' do
        admin = create(:user, :admin)
        announcement1 = create(:announcement, :published, author: admin, published_at: 3.days.ago, expires_at: nil,
                                                          display_order: 1)
        announcement2 = create(:announcement, :published, author: admin, published_at: 1.day.ago, expires_at: nil,
                                                          display_order: 0)
        announcement3 = create(:announcement, :published, author: admin, published_at: 2.days.ago, expires_at: nil,
                                                          display_order: 0)

        expect(Announcement.active).to eq([announcement2, announcement3, announcement1])
      end
    end

    describe '.recent' do
      it '作成日時の降順で返す' do
        admin = create(:user, :admin)
        announcement1 = create(:announcement, author: admin, created_at: 3.days.ago)
        announcement2 = create(:announcement, author: admin, created_at: 1.day.ago)
        announcement3 = create(:announcement, author: admin, created_at: 2.days.ago)

        expect(Announcement.recent).to eq([announcement2, announcement3, announcement1])
      end
    end
  end

  describe '#active?' do
    let(:admin) { create(:user, :admin) }

    it '公開中かつ有効期限内の場合はtrue' do
      announcement = create(:announcement, :published, author: admin, published_at: 1.day.ago,
                                                       expires_at: 1.day.from_now)
      expect(announcement.active?).to be true
    end

    it '期限切れの場合はfalse' do
      announcement = create(:announcement, :published, author: admin, published_at: 2.days.ago, expires_at: 1.day.ago)
      expect(announcement.active?).to be false
    end

    it '下書きの場合はfalse' do
      announcement = create(:announcement, :draft, author: admin)
      expect(announcement.active?).to be false
    end

    it '未来の公開日の場合はfalse' do
      announcement = create(:announcement, :published, author: admin, published_at: 1.day.from_now, expires_at: nil)
      expect(announcement.active?).to be false
    end

    it '有効期限がnilの場合は期限切れにならない' do
      announcement = create(:announcement, :published, author: admin, published_at: 1.day.ago, expires_at: nil)
      expect(announcement.active?).to be true
    end
  end

  describe '#expired?' do
    let(:admin) { create(:user, :admin) }

    it '期限切れの場合はtrue' do
      announcement = create(:announcement, :published, author: admin, published_at: 2.days.ago, expires_at: 1.day.ago)
      expect(announcement.expired?).to be true
    end

    it '有効期限内の場合はfalse' do
      announcement = create(:announcement, :published, author: admin, published_at: 1.day.ago,
                                                       expires_at: 1.day.from_now)
      expect(announcement.expired?).to be false
    end

    it '有効期限がnilの場合はfalse' do
      announcement = create(:announcement, :published, author: admin, published_at: 1.day.ago, expires_at: nil)
      expect(announcement.expired?).to be false
    end
  end
end
