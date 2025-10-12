FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_oauth do
      provider { 'google_oauth2' }
      uid { Faker::Number.number(digits: 10) }
    end
  end
end
