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
      after(:build) do |template|
        3.times do |i|
          template.consent_form_items.build(
            content: "同意項目#{i + 1}",
            position: i + 1,
            is_required: i.zero?
          )
        end
      end
    end
  end
end
