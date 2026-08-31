FactoryBot.define do
  factory :tag do
    user
    sequence(:name) { |n| "タグ#{n}" }
    category { %w[施術 症状 診断 部位].sample }
    color { '#3B82F6' }

    trait :with_medical_records do
      after(:create) do |tag|
        create_list(:medical_record, 3, user: tag.user, tags: [tag])
      end
    end
  end
end
