FactoryBot.define do
  factory :inquiry_message do
    association :inquiry
    association :user
    sequence(:body) { |n| "お問い合わせ本文です#{n}。" }
  end
end
