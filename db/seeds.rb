# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ユーザーの作成
user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
end

puts "User created: #{user.email}"

# コストシートのサンプルデータ作成
cost_sheets_data = [
  { item_name: 'フェイシャル基本施術', standard_price: 8000, category: 'treatment', memo: '60分コース' },
  { item_name: 'ボディケア全身', standard_price: 12_000, category: 'treatment', memo: '90分コース' },
  { item_name: 'ヘッドスパ', standard_price: 5000, category: 'treatment', memo: '30分コース' },
  { item_name: 'ボトックス注射', standard_price: 30_000, category: 'medicine', memo: '1部位' },
  { item_name: 'ヒアルロン酸注入', standard_price: 50_000, category: 'medicine', memo: '1cc' },
  { item_name: '消毒液', standard_price: 500, category: 'supplies', memo: '施術時使用' },
  { item_name: 'カウンセリング料', standard_price: 3000, category: 'other', memo: '初回のみ' },
]

cost_sheets_data.each do |data|
  CostSheet.find_or_create_by!(user: user, item_name: data[:item_name]) do |cs|
    cs.standard_price = data[:standard_price]
    cs.category = data[:category]
    cs.memo = data[:memo]
  end
end

puts "#{CostSheet.count} cost sheets created"
