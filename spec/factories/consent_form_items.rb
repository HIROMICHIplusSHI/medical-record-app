FactoryBot.define do
  factory :consent_form_item do
    association :consent_form_template
    sequence(:content) { |n| "同意項目#{n}" }
    sequence(:position)
    is_required { true }

    trait :optional do
      is_required { false }
    end
  end
end
