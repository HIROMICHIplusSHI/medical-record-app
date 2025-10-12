FactoryBot.define do
  factory :questionnaire do
    patient
    medical_history { '特になし' }
    current_medications { '特になし' }
    allergies { '特になし' }
    past_surgeries { '特になし' }
    family_history { '特になし' }
    lifestyle_notes { '規則正しい生活を心がけています' }
    concerns { '健康維持について相談したい' }

    trait :with_medical_conditions do
      medical_history { '高血圧、糖尿病の既往歴あり' }
      current_medications { 'アムロジピン 5mg、メトホルミン 500mg' }
      allergies { '花粉症、猫アレルギー' }
      past_surgeries { '虫垂炎手術（2015年）、胆嚢摘出術（2018年）' }
      family_history { '父親が糖尿病、母親が高血圧' }
      lifestyle_notes { '喫煙歴10年（現在禁煙中）、飲酒は週に2-3回' }
      concerns { '最近疲れやすく、体重が増加傾向' }
    end
  end
end
