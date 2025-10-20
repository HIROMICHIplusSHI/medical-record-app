require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { create(:user, role: :admin) }
  let(:other_admin) { create(:user, role: :admin) }
  let(:user) { create(:user, role: :user) }
  let(:other_user) { create(:user, role: :user) }

  describe '#index?' do
    it '管理者はユーザー一覧にアクセスできる' do
      policy = described_class.new(admin, User)
      expect(policy.index?).to be true
    end

    it '一般ユーザーはユーザー一覧にアクセスできない' do
      policy = described_class.new(user, User)
      expect(policy.index?).to be false
    end
  end

  describe '#show?' do
    it '管理者は他のユーザーの詳細にアクセスできる' do
      policy = described_class.new(admin, user)
      expect(policy.show?).to be true
    end

    it '一般ユーザーは他のユーザーの詳細にアクセスできない' do
      policy = described_class.new(user, other_user)
      expect(policy.show?).to be false
    end
  end

  describe '#toggle_role?' do
    context '管理者の場合' do
      it '他のユーザーの権限を変更できる' do
        policy = described_class.new(admin, user)
        expect(policy.toggle_role?).to be true
      end

      it '他の管理者の権限を変更できる' do
        policy = described_class.new(admin, other_admin)
        expect(policy.toggle_role?).to be true
      end

      it '自分自身の権限もポリシーレベルでは許可される（コントローラーでチェック）' do
        policy = described_class.new(admin, admin)
        expect(policy.toggle_role?).to be true
      end
    end

    context '一般ユーザーの場合' do
      it '他のユーザーの権限を変更できない' do
        policy = described_class.new(user, other_user)
        expect(policy.toggle_role?).to be false
      end

      it '管理者の権限を変更できない' do
        policy = described_class.new(user, admin)
        expect(policy.toggle_role?).to be false
      end

      it '自分自身の権限も変更できない' do
        policy = described_class.new(user, user)
        expect(policy.toggle_role?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:admin1) { create(:user, role: :admin) }
    let!(:admin2) { create(:user, role: :admin) }
    let!(:user1) { create(:user, role: :user) }
    let!(:user2) { create(:user, role: :user) }

    context '管理者の場合' do
      it 'すべてのユーザーにアクセスできる' do
        scope = Pundit.policy_scope!(admin1, User)
        expect(scope).to contain_exactly(admin1, admin2, user1, user2)
      end
    end

    context '一般ユーザーの場合' do
      it '自分自身のみアクセスできる' do
        scope = Pundit.policy_scope!(user1, User)
        expect(scope).to contain_exactly(user1)
      end
    end
  end
end
