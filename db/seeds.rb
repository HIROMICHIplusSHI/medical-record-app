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

# 施術場所のサンプルデータ作成
facilities_data = [
  { name: '本院（東京）', address: '東京都渋谷区〇〇1-2-3', phone: '03-1234-5678' },
  { name: '大阪分院', address: '大阪府大阪市北区△△2-3-4', phone: '06-2345-6789' },
  { name: '名古屋分院', address: '愛知県名古屋市中区□□3-4-5', phone: '052-3456-7890' },
  { name: '福岡分院', address: '福岡県福岡市中央区◇◇4-5-6', phone: '092-4567-8901' },
]

facilities_data.each do |data|
  Facility.find_or_create_by!(user: user, name: data[:name]) do |f|
    f.address = data[:address]
    f.phone = data[:phone]
  end
end

puts "#{Facility.count} facilities created"
