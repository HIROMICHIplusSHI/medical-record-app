require 'rails_helper'

RSpec.describe AnnouncementPolicy, type: :policy do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user, role: :user) }
  let(:announcement) { create(:announcement, author: admin) }

  describe '#index?' do
    it '管理者はお知らせ一覧にアクセスできる' do
      policy = described_class.new(admin, Announcement)
      expect(policy.index?).to be true
    end

    it '一般ユーザーはお知らせ一覧にアクセスできない' do
      policy = described_class.new(user, Announcement)
      expect(policy.index?).to be false
    end
  end

  describe '#show?' do
    it '管理者はお知らせ詳細にアクセスできる' do
      policy = described_class.new(admin, announcement)
      expect(policy.show?).to be true
    end

    it '一般ユーザーはお知らせ詳細にアクセスできない' do
      policy = described_class.new(user, announcement)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it '管理者はお知らせを作成できる' do
      policy = described_class.new(admin, Announcement)
      expect(policy.create?).to be true
    end

    it '一般ユーザーはお知らせを作成できない' do
      policy = described_class.new(user, Announcement)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    it '管理者はお知らせを更新できる' do
      policy = described_class.new(admin, announcement)
      expect(policy.update?).to be true
    end

    it '一般ユーザーはお知らせを更新できない' do
      policy = described_class.new(user, announcement)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it '管理者はお知らせを削除できる' do
      policy = described_class.new(admin, announcement)
      expect(policy.destroy?).to be true
    end

    it '一般ユーザーはお知らせを削除できない' do
      policy = described_class.new(user, announcement)
      expect(policy.destroy?).to be false
    end
  end

  describe '#publish?' do
    it '管理者は下書きを公開できる' do
      draft_announcement = create(:announcement, author: admin, status: :draft)
      policy = described_class.new(admin, draft_announcement)
      expect(policy.publish?).to be true
    end

    it '一般ユーザーは下書きを公開できない' do
      draft_announcement = create(:announcement, author: admin, status: :draft)
      policy = described_class.new(user, draft_announcement)
      expect(policy.publish?).to be false
    end
  end

  describe '#archive?' do
    it '管理者は公開中のお知らせをアーカイブできる' do
      published_announcement = create(:announcement, :published, author: admin)
      policy = described_class.new(admin, published_announcement)
      expect(policy.archive?).to be true
    end

    it '一般ユーザーは公開中のお知らせをアーカイブできない' do
      published_announcement = create(:announcement, :published, author: admin)
      policy = described_class.new(user, published_announcement)
      expect(policy.archive?).to be false
    end
  end

  describe 'Scope' do
    let!(:draft_announcement) { create(:announcement, author: admin, status: :draft) }
    let!(:published_announcement) { create(:announcement, :published, author: admin) }
    let!(:archived_announcement) { create(:announcement, author: admin, status: :archived) }

    context '管理者の場合' do
      it 'すべてのお知らせにアクセスできる' do
        scope = Pundit.policy_scope!(admin, Announcement)
        expect(scope).to contain_exactly(draft_announcement, published_announcement, archived_announcement)
      end
    end

    context '一般ユーザーの場合' do
      it '公開中のお知らせのみアクセスできる' do
        scope = Pundit.policy_scope!(user, Announcement)
        expect(scope).to contain_exactly(published_announcement)
      end
    end
  end
end
