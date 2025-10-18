FactoryBot.define do
  factory :consent_item_response do
    association :patient_consent
    association :consent_form_item
    checked { true }

    trait :unchecked do
      checked { false }
    end
  end
end
