FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :user }
    terms_accepted_at { Time.current }
    privacy_accepted_at { Time.current }

    # 招待コード用トランジェント属性
    transient do
      create_invitation_code { true }
    end

    # 招待コード作成と設定
    before(:create) do |user, evaluator|
      if evaluator.create_invitation_code
        # 管理者ユーザーを作成（招待コードの作成者として必要）
        admin = User.find_by(role: :admin) || begin
          # 既存の管理者がいない場合は作成（招待コード検証をスキップ）
          temp_admin = User.new(
            name: 'Admin',
            email: 'admin@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: :admin,
            terms_accepted_at: Time.current,
            privacy_accepted_at: Time.current
          )
          # 招待コード検証をスキップ（管理者は特別扱い）
          temp_admin.save(validate: false)
          temp_admin
        end

        # 招待コードを作成
        code = InvitationCode.create!(
          code: "TEST#{SecureRandom.alphanumeric(4).upcase}",
          created_by: admin,
          max_uses: nil,
          status: :active
        )

        user.invitation_code_input = code.code
      end
    end

    trait :admin do
      role { :admin }
    end

    trait :with_oauth do
      provider { 'google_oauth2' }
      uid { Faker::Number.number(digits: 10) }
    end

    trait :without_terms_acceptance do
      terms_accepted_at { nil }
      privacy_accepted_at { nil }
    end
  end
end
