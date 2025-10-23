FactoryBot.define do
  factory :medical_record do
    association :patient
    association :facility
    association :user
    visit_date { Date.today }
    treatment_content { 'ボトックス注射を実施' }

    # コスト項目付きのトレイトを追加
    trait :with_cost_items do
      after(:create) do |medical_record|
        create_list(:cost_item, 2, medical_record: medical_record)
      end
    end
  end
end
