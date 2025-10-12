FactoryBot.define do
  factory :facility do
    user
    name { "#{Faker::Company.name}クリニック" }
    address { Faker::Address.full_address }
    phone { '03-1234-5678' }
    email { Faker::Internet.email }
    notes { '毎週土曜日のみ施術' }

    trait :with_records do
      after(:create) do |facility|
        create_list(:medical_record, 3, facility: facility, user: facility.user)
      end
    end
  end
end
