FactoryBot.define do
  factory :medical_record do
    association :patient
    association :facility
    association :user
    visit_date { Date.today }
    treatment_location { '顔全体' }
    chief_complaint { 'しわやたるみが気になる' }
    diagnosis { '加齢による皮膚の弾力低下' }
    treatment_content { 'ボトックス注射を実施' }
    notes { '次回は3ヶ月後に経過観察' }

    # コスト項目付きのトレイトを追加
    trait :with_cost_items do
      after(:create) do |medical_record|
        create_list(:cost_item, 2, medical_record: medical_record)
      end
    end
  end
end
