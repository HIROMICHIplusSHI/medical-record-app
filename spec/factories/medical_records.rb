FactoryBot.define do
  factory :medical_record do
    user
    # 施術記録・患者・施設は同一ユーザーに属している必要がある（MedicalRecord のバリデーション）
    patient { association :patient, user: user }
    facility { association :facility, user: user }
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
