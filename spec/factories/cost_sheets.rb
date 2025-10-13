FactoryBot.define do
  factory :cost_sheet do
    association :user
    sequence(:item_name) { |n| "施術項目#{n}" }
    standard_price { 5000 }
    category { 'treatment' }
    memo { '標準的な施術です' }

    trait :medicine do
      item_name { 'ボトックス注射' }
      standard_price { 30_000 }
      category { 'medicine' }
    end

    trait :supplies do
      item_name { '消毒液' }
      standard_price { 500 }
      category { 'supplies' }
    end

    trait :other do
      item_name { 'その他費用' }
      standard_price { 1000 }
      category { 'other' }
    end

    trait :expensive do
      standard_price { 100_000 }
    end
  end
end
