# frozen_string_literal: true

FactoryBot.define do
  factory :invitation_code do
    sequence(:code) { |n| "CODE#{format('%04d', n)}" }
    max_uses { nil } # デフォルトは無制限
    used_count { 0 }
    expires_at { nil } # デフォルトは無期限
    status { :active }
    memo { 'テスト用招待コード' }

    # 無限ループを避けるため、admin traitで create_invitation_code: false を指定
    association :created_by, factory: [:user, :admin, { create_invitation_code: false }]

    # 使用回数制限ありの招待コード
    trait :with_max_uses do
      max_uses { 5 }
    end

    # 有効期限ありの招待コード
    trait :with_expiration do
      expires_at { 1.month.from_now }
    end

    # 期限切れの招待コード
    trait :expired do
      expires_at { 1.day.ago }
    end

    # 無効化された招待コード
    trait :inactive do
      status { :inactive }
    end

    # 使用回数上限に達した招待コード
    trait :max_uses_reached do
      max_uses { 3 }
      used_count { 3 }
    end

    # 完全に使用可能な招待コード（制限付き）
    trait :fully_available do
      max_uses { 10 }
      used_count { 0 }
      expires_at { 1.month.from_now }
      status { :active }
    end
  end
end
