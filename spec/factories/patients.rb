FactoryBot.define do
  factory :patient do
    user
    name { Faker::Name.name }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 80) }
    gender { :female }
    phone { '090-1234-5678' }
    email { Faker::Internet.email }
    address { Faker::Address.full_address }
    emergency_contact { '03-1234-5678' }

    trait :male do
      gender { :male }
    end

    trait :unspecified_gender do
      gender { :unspecified }
    end

    trait :with_questionnaire do
      after(:create) do |patient|
        create(:questionnaire, patient: patient)
      end
    end
  end
end
