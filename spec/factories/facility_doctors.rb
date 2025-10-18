FactoryBot.define do
  factory :facility_doctor do
    association :facility
    name { '山田太郎医師' }
    medical_license_number { "医#{Faker::Number.number(digits: 6)}" }
    specialization { '美容外科' }
  end
end
