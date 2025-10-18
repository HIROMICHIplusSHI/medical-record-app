FactoryBot.define do
  factory :patient_consent do
    association :patient
    association :consent_form_template
    association :medical_record
    association :facility_doctor
    association :user

    agreed_at { Time.current }
    signature_data do
      'data:image/png;base64,' \
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    end
    signed_ip { '192.168.1.1' }
    signed_user_agent { 'Mozilla/5.0' }

    trait :with_responses do
      after(:create) do |consent|
        consent.consent_form_template.consent_form_items.each do |item|
          create(:consent_item_response,
                 patient_consent: consent,
                 consent_form_item: item,
                 checked: true)
        end
      end
    end
  end
end
