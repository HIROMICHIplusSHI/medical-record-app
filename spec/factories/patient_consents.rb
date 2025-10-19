FactoryBot.define do
  factory :patient_consent do
    # 関連を適切に設定（認可チェック対応）
    user
    patient { association :patient, user: user }
    consent_form_template { association :consent_form_template, :with_items, user: user }
    medical_record do
      association :medical_record,
                  user: user,
                  patient: patient,
                  facility: association(:facility, user: user)
    end
    facility_doctor do
      association :facility_doctor,
                  facility: medical_record.facility
    end

    agreed_at { Time.current }
    # 50x50ピクセルの白い背景PNG（約600バイト、署名データバリデーション対応）
    signature_data do
      'data:image/png;base64,' \
        'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz' \
        'AAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAAW' \
        'dEVYdENyZWF0aW9uIFRpbWUAMDUvMDcvMjAxNkZWFf8AAAAgSURBVGiB7cEBDQAAAMKg909tDwcU' \
        'AAAAAAAAAAAAAAAAgMEDEFAAAes7OygAAAAASUVORK5CYII='
    end
    signed_ip { '192.168.1.1' }
    signed_user_agent { 'Mozilla/5.0' }

    trait :with_responses do
      after(:build) do |consent|
        consent.consent_form_template.consent_form_items.each do |item|
          consent.consent_item_responses.build(
            consent_form_item: item,
            checked: true
          )
        end
      end
    end
  end
end
