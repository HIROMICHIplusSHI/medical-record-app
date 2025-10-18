FactoryBot.define do
  factory :consent_form_template do
    association :user
    sequence(:title) { |n| "同意書テンプレート#{n}" }
    description { '施術前に必ずご確認ください。' }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :with_items do
      after(:create) do |template|
        create_list(:consent_form_item, 3, consent_form_template: template)
      end
    end
  end
end
