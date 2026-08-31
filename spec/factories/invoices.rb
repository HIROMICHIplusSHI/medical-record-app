FactoryBot.define do
  factory :invoice do
    user
    # 請求書と施設は同一ユーザーに属している必要がある（Invoice のバリデーション）。
    # facility だけを指定して呼ばれる箇所があるため、施設が渡された場合は所有者をそちらに合わせる。
    facility { association :facility, user: user }

    after(:build) do |invoice|
      invoice.user = invoice.facility.user if invoice.facility&.user.present?
    end

    sequence(:invoice_number) { |n| "INV-#{Date.current.strftime('%Y%m')}-#{n.to_s.rjust(4, '0')}" }
    issued_at { Time.current }
    billing_period_start { Date.current.beginning_of_month }
    billing_period_end { Date.current.end_of_month }
    total_amount { 0.0 }
    status { :draft }
    sent_at { nil }
    notes { nil }

    trait :issued do
      status { :issued }
    end

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :paid do
      status { :paid }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_items do
      after(:create) do |invoice|
        create_list(:invoice_item, 3, invoice: invoice)
      end
    end
  end
end
