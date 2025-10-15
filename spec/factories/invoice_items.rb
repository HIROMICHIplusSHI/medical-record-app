FactoryBot.define do
  factory :invoice_item do
    association :invoice
    association :medical_record

    description { '診察料' }
    amount { 5000.0 }

    trait :expensive do
      amount { 50_000.0 }
    end

    trait :free do
      amount { 0.0 }
    end

    trait :with_custom_description do
      description { '特別診療費' }
    end
  end
end
