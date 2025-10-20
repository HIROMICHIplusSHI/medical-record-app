FactoryBot.define do
  factory :announcement do
    association :author, factory: :user
    title { Faker::Lorem.sentence(word_count: 5) }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :draft }
    severity { :info }
    published_at { nil }
    expires_at { nil }
    display_order { 0 }

    trait :published do
      status { :published }
      published_at { 1.day.ago }
    end

    trait :archived do
      status { :archived }
    end

    trait :warning do
      severity { :warning }
    end

    trait :critical do
      severity { :critical }
    end

    trait :with_expiry do
      expires_at { 1.week.from_now }
    end
  end
end
