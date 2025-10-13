FactoryBot.define do
  factory :cost_item do
    association :medical_record
    item_name { 'ボトックス注射' }
    quantity { 1 }
    unit_price { 50_000 }
    # total_priceはcallbackで自動計算される
  end
end
