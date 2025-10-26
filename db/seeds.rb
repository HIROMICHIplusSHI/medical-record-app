# デモ版用Seedデータ
# 実行方法: rails db:seed (本番環境ではRenderコンソールから実行)

puts '=========================================='
puts 'デモ版Seedデータ作成開始'
puts '=========================================='

# ========================================
# 1. 管理者アカウントの作成
# ========================================
admin = User.find_or_create_by!(email: 'admin@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'admin'
end
puts "✅ 管理者アカウント作成: #{admin.email} (role: #{admin.role})"

# ========================================
# 2. お知らせの作成（管理者のみ作成可能）
# ========================================
announcements_data = [
  {
    title: 'InkFolioデモ版へようこそ',
    content: 'この度はInkFolioデモ版をご利用いただきありがとうございます。本システムは技術デモンストレーション・ポートフォリオ展示を目的としたデモ版です。実在する患者・顧客の個人情報は入力しないでください。',
    published: true,
    published_at: 1.day.ago,
  },
  {
    title: 'デモアカウント情報',
    content: "デモユーザーアカウント:\nメールアドレス: demo@example.com\nパスワード: password123\n\n上記アカウントで施術者として各種機能をお試しいただけます。",
    published: true,
    published_at: 2.days.ago,
  },
  {
    title: '主な機能のご紹介',
    content: "InkFolioでは以下の機能をご利用いただけます：\n\n・患者管理（カルテ・問診票）\n・施術記録管理\n・売上・請求書管理\n・施術場所管理\n・コストシート管理\n\nぜひ各機能をお試しください。",
    published: true,
    published_at: 3.days.ago,
  },
  {
    title: 'テストデータについて',
    content: '本デモ版に含まれるすべてのデータは架空のテストデータです。実在する個人・団体とは一切関係ありません。',
    published: true,
    published_at: 4.days.ago,
  },
]

announcements_data.each do |data|
  Announcement.find_or_create_by!(title: data[:title]) do |a|
    a.content = data[:content]
    a.published = data[:published]
    a.published_at = data[:published_at]
  end
end
puts "✅ お知らせ作成: #{Announcement.count}件"

# ========================================
# 3. デモユーザー（アートメイク施術者）の作成
# ========================================
demo_user = User.find_or_create_by!(email: 'demo@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'user'
end
puts "✅ デモユーザー作成: #{demo_user.email} (role: #{demo_user.role})"

# ========================================
# 4. 施術場所の作成
# ========================================
facilities_data = [
  { name: '青山美容クリニック', address: '東京都港区南青山1-1-1 青山ビル3F', phone: '03-1234-5678', billing_percentage: 70 },
  { name: '表参道メディカルサロン', address: '東京都渋谷区神宮前5-2-3 表参道プラザ2F', phone: '03-2345-6789', billing_percentage: 65 },
  { name: '銀座ビューティークリニック', address: '東京都中央区銀座4-3-2 銀座タワー5F', phone: '03-3456-7890', billing_percentage: 75 },
]

facilities = []
facilities_data.each do |data|
  facility = Facility.find_or_create_by!(user: demo_user, name: data[:name]) do |f|
    f.address = data[:address]
    f.phone = data[:phone]
    f.billing_percentage = data[:billing_percentage]
  end
  facilities << facility
end
puts "✅ 施術場所作成: #{Facility.where(user: demo_user).count}件"

# ========================================
# 5. コストシート（アートメイク用）の作成
# ========================================
cost_sheets_data = [
  { item_name: '眉アートメイク（2D）', standard_price: 60_000, category: 'treatment', memo: '初回施術' },
  { item_name: '眉アートメイク（3D）', standard_price: 80_000, category: 'treatment', memo: '毛並み技法' },
  { item_name: '眉アートメイク（4D）', standard_price: 100_000, category: 'treatment', memo: 'コンビネーション技法' },
  { item_name: 'アイライン上', standard_price: 50_000, category: 'treatment', memo: '上まぶたのみ' },
  { item_name: 'アイライン上下', standard_price: 70_000, category: 'treatment', memo: '上下セット' },
  { item_name: 'リップアートメイク', standard_price: 90_000, category: 'treatment', memo: 'フルリップ' },
  { item_name: 'リタッチ（眉）', standard_price: 30_000, category: 'treatment', memo: '2回目以降' },
  { item_name: 'カウンセリング料', standard_price: 3000, category: 'other', memo: '初回のみ' },
  { item_name: '色素（ブラウン系）', standard_price: 8000, category: 'supplies', memo: '施術時使用' },
  { item_name: '色素（グレー系）', standard_price: 8000, category: 'supplies', memo: '施術時使用' },
  { item_name: '麻酔クリーム', standard_price: 2000, category: 'medicine', memo: '施術時使用' },
  { item_name: '針（使い捨て）', standard_price: 1500, category: 'supplies', memo: '1本' },
  { item_name: 'グローブ', standard_price: 500, category: 'supplies', memo: '1セット' },
  { item_name: '消毒液', standard_price: 800, category: 'supplies', memo: '施術前後' },
]

cost_sheets_data.each do |data|
  CostSheet.find_or_create_by!(user: demo_user, item_name: data[:item_name]) do |cs|
    cs.standard_price = data[:standard_price]
    cs.category = data[:category]
    cs.memo = data[:memo]
  end
end
puts "✅ コストシート作成: #{CostSheet.where(user: demo_user).count}件"

# ========================================
# 6. 患者の作成（テストデータ）
# ========================================
patients_data = [
  {
    name: '山田花子',
    name_kana: 'ヤマダハナコ',
    date_of_birth: Date.new(1990, 5, 15),
    gender: 'female',
    phone: '090-1234-5678',
    email: 'hanako.yamada@example.com',
    address: '東京都テスト区サンプル町1-1-1',
    medical_history: 'アレルギー: なし',
    memo: '初回カウンセリング済み',
  },
  {
    name: '田中美咲',
    name_kana: 'タナカミサキ',
    date_of_birth: Date.new(1985, 8, 22),
    gender: 'female',
    phone: '090-2345-6789',
    email: 'misaki.tanaka@example.com',
    address: '東京都テスト区サンプル町2-2-2',
    medical_history: '金属アレルギーあり',
    memo: 'リピーター',
  },
  {
    name: '佐藤結衣',
    name_kana: 'サトウユイ',
    date_of_birth: Date.new(1995, 3, 10),
    gender: 'female',
    phone: '090-3456-7890',
    email: 'yui.sato@example.com',
    address: '東京都テスト区サンプル町3-3-3',
    medical_history: 'アレルギー: なし',
    memo: 'SNS経由の新規顧客',
  },
  {
    name: '鈴木愛',
    name_kana: 'スズキアイ',
    date_of_birth: Date.new(1988, 12, 5),
    gender: 'female',
    phone: '090-4567-8901',
    email: 'ai.suzuki@example.com',
    address: '東京都テスト区サンプル町4-4-4',
    medical_history: '薬剤アレルギー: ペニシリン系',
    memo: '友人紹介',
  },
]

patients = []
patients_data.each do |data|
  patient = Patient.find_or_create_by!(user: demo_user, email: data[:email]) do |p|
    p.name = data[:name]
    p.name_kana = data[:name_kana]
    p.date_of_birth = data[:date_of_birth]
    p.gender = data[:gender]
    p.phone = data[:phone]
    p.address = data[:address]
    p.medical_history = data[:medical_history]
    p.memo = data[:memo]
  end
  patients << patient
end
puts "✅ 患者作成: #{Patient.where(user: demo_user).count}件"

# ========================================
# 7. カルテの作成
# ========================================
# 患者1: 山田花子 - 眉アートメイク初回
if patients[0]
  medical_record1 = MedicalRecord.find_or_create_by!(
    user: demo_user,
    patient: patients[0],
    facility: facilities[0],
    treatment_date: 2.weeks.ago.to_date
  ) do |mr|
    mr.treatment_content = '眉アートメイク（4D）初回施術'
    mr.notes = <<~NOTES
      施術内容：
      ・デザイン決定（ナチュラルアーチ型）
      ・色味：ライトブラウン
      ・技法：4Dコンビネーション（毛並み＋パウダー）
      ・麻酔：クリーム麻酔使用
      ・施術時間：約2時間

      経過観察：
      ・痛み：軽度（麻酔効果良好）
      ・腫れ：なし
      ・アフターケア指導済み

      次回予約：4週間後リタッチ予定
    NOTES
    mr.billing_amount = 100_000
  end

  # カルテにコスト項目を追加
  [
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '眉アートメイク（4D）'), quantity: 1, unit_price: 100_000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '色素（ブラウン系）'), quantity: 1, unit_price: 8000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '麻酔クリーム'), quantity: 1, unit_price: 2000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '針（使い捨て）'), quantity: 1, unit_price: 1500 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: 'グローブ'), quantity: 1, unit_price: 500 },
  ].each do |item_data|
    next unless item_data[:cost_sheet]

    CostItem.find_or_create_by!(
      medical_record: medical_record1,
      cost_sheet: item_data[:cost_sheet]
    ) do |ci|
      ci.quantity = item_data[:quantity]
      ci.unit_price = item_data[:unit_price]
    end
  end
end

# 患者2: 田中美咲 - アイライン上
if patients[1]
  medical_record2 = MedicalRecord.find_or_create_by!(
    user: demo_user,
    patient: patients[1],
    facility: facilities[1],
    treatment_date: 1.week.ago.to_date
  ) do |mr|
    mr.treatment_content = 'アイライン上施術'
    mr.notes = <<~NOTES
      施術内容：
      ・デザイン決定（まつ毛の間を埋める自然なライン）
      ・色味：ダークブラウン
      ・麻酔：クリーム麻酔使用
      ・施術時間：約1.5時間

      経過観察：
      ・痛み：中程度（目元のため若干敏感）
      ・腫れ：軽度（翌日にはほぼ消失予定）
      ・アフターケア指導済み

      注意事項：
      ・1週間はアイメイク禁止
      ・コンタクトレンズ使用再開は3日後から
    NOTES
    mr.billing_amount = 50_000
  end

  [
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: 'アイライン上'), quantity: 1, unit_price: 50_000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '色素（ブラウン系）'), quantity: 1, unit_price: 8000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '麻酔クリーム'), quantity: 1, unit_price: 2000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '針（使い捨て）'), quantity: 1, unit_price: 1500 },
  ].each do |item_data|
    next unless item_data[:cost_sheet]

    CostItem.find_or_create_by!(
      medical_record: medical_record2,
      cost_sheet: item_data[:cost_sheet]
    ) do |ci|
      ci.quantity = item_data[:quantity]
      ci.unit_price = item_data[:unit_price]
    end
  end
end

# 患者3: 佐藤結衣 - 眉アートメイク（2D）
if patients[2]
  medical_record3 = MedicalRecord.find_or_create_by!(
    user: demo_user,
    patient: patients[2],
    facility: facilities[2],
    treatment_date: 3.days.ago.to_date
  ) do |mr|
    mr.treatment_content = '眉アートメイク（2D）初回施術'
    mr.notes = <<~NOTES
      施術内容：
      ・デザイン決定（ストレート型）
      ・色味：ミディアムブラウン
      ・技法：2Dグラデーション
      ・麻酔：クリーム麻酔使用
      ・施術時間：約1.5時間

      経過観察：
      ・痛み：ほぼなし
      ・腫れ：なし
      ・色の定着良好
      ・アフターケア指導済み

      次回予約：6週間後リタッチ予定
    NOTES
    mr.billing_amount = 60_000
  end

  [
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '眉アートメイク（2D）'), quantity: 1, unit_price: 60_000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '色素（ブラウン系）'), quantity: 1, unit_price: 8000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '麻酔クリーム'), quantity: 1, unit_price: 2000 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: '針（使い捨て）'), quantity: 1, unit_price: 1500 },
    { cost_sheet: CostSheet.find_by(user: demo_user, item_name: 'グローブ'), quantity: 1, unit_price: 500 },
  ].each do |item_data|
    next unless item_data[:cost_sheet]

    CostItem.find_or_create_by!(
      medical_record: medical_record3,
      cost_sheet: item_data[:cost_sheet]
    ) do |ci|
      ci.quantity = item_data[:quantity]
      ci.unit_price = item_data[:unit_price]
    end
  end
end

puts "✅ カルテ作成: #{MedicalRecord.where(user: demo_user).count}件"

# ========================================
# 完了メッセージ
# ========================================
puts '=========================================='
puts '✨ デモ版Seedデータ作成完了！'
puts '=========================================='
puts ''
puts '📋 作成されたデータ：'
puts '  - 管理者アカウント: 1件'
puts "  - お知らせ: #{Announcement.count}件"
puts '  - デモユーザー: 1件'
puts "  - 施術場所: #{Facility.where(user: demo_user).count}件"
puts "  - コストシート: #{CostSheet.where(user: demo_user).count}件"
puts "  - 患者: #{Patient.where(user: demo_user).count}件"
puts "  - カルテ: #{MedicalRecord.where(user: demo_user).count}件"
puts ''
puts '🔐 ログイン情報：'
puts '  管理者:'
puts '    メール: admin@example.com'
puts '    パスワード: password123'
puts ''
puts '  デモユーザー（施術者）:'
puts '    メール: demo@example.com'
puts '    パスワード: password123'
puts ''
puts '=========================================='
