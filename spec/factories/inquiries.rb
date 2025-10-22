FactoryBot.define do
  factory :inquiry do
    association :user
    sequence(:subject) { |n| "お問い合わせ件名#{n}" }
    status { :open }

    trait :in_progress do
      status { :in_progress }
    end

    trait :closed do
      status { :closed }
    end

    trait :with_messages do
      after(:create) do |inquiry|
        create_list(:inquiry_message, 3, inquiry: inquiry, user: inquiry.user)
      end
    end
  end
end
