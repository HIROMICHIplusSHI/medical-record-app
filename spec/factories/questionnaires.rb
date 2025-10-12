FactoryBot.define do
  factory :questionnaire do
    patient

    # 基本情報（必須）
    full_name { '山田 太郎' }
    full_name_kana { 'ヤマダ タロウ' }
    birth_date { '1990-01-01' }
    gender { 'male' }
    phone { '090-1234-5678' }
    email { 'test@example.com' }
    postal_code { '100-0001' }
    address { '東京都千代田区1-1-1' }
    emergency_contact { '山田花子（妻） 090-9876-5432' }

    # 医療情報
    medical_conditions { 'なし' }
    current_medications { 'なし' }
    allergies { 'なし' }
    past_surgeries { 'なし' }
    pregnancy_info { '該当なし' }

    # 施術情報
    desired_treatments { '眉毛アートメイク' }
    past_treatments { 'なし' }
    skin_conditions { '普通肌' }
    other_concerns { '特になし' }

    trait :with_medical_conditions do
      full_name { '田中 花子' }
      full_name_kana { 'タナカ ハナコ' }
      birth_date { '1985-05-15' }
      gender { 'female' }
      medical_conditions { '高血圧、治療中' }
      current_medications { 'アムロジピン 5mg、メトホルミン 500mg' }
      allergies { '花粉症、猫アレルギー' }
      past_surgeries { '虫垂炎手術（2015年）' }
      pregnancy_info { '該当なし' }
      desired_treatments { '眉毛、リップアートメイク' }
      past_treatments { '2020年に眉のアートメイク経験あり' }
      skin_conditions { '敏感肌、乾燥しやすい' }
      other_concerns { '自然な仕上がりを希望' }
    end
  end
end
