# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DemoSession do
  describe '.enabled?' do
    it 'DEMO_LOGIN_ENABLED が true のとき有効になること' do
      allow(ENV).to receive(:fetch).with('DEMO_LOGIN_ENABLED', 'false').and_return('true')

      expect(described_class).to be_enabled
    end

    it '環境変数が未設定のとき無効であること（デフォルト無効）' do
      allow(ENV).to receive(:fetch).with('DEMO_LOGIN_ENABLED', 'false').and_return('false')

      expect(described_class).not_to be_enabled
    end
  end

  describe '.user' do
    it '一般ユーザーロールのデモユーザーを返すこと' do
      demo_user = create(:user, email: described_class::DEMO_EMAIL, role: :user)

      expect(described_class.user).to eq(demo_user)
    end

    it '【杭1】デモ用メールアドレスが admin ロールの場合は nil を返すこと' do
      create(:user, email: described_class::DEMO_EMAIL, role: :admin)

      expect(described_class.user).to be_nil
    end

    it 'デモユーザーが存在しない場合は nil を返すこと' do
      expect(described_class.user).to be_nil
    end
  end
end
