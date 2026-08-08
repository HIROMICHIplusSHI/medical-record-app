# デモ版用Seedデータ
# 実行方法: rails db:seed（本番では bin/render-build.sh から自動実行）
#
# 冪等性: すべて find_or_create_by! を使用しているため、再実行しても重複しない。

puts '=========================================='
puts 'デモ版Seedデータ作成開始'
puts '=========================================='

# ========================================
# 1. 管理者アカウントの作成
# ========================================
# NOTE: User は作成時に利用規約・プライバシーポリシー同意が必須（Phase 7で追加）。
#       管理者は招待コードのバリデーションが免除される（skip_invitation_code_validation?）。
admin = User.find_or_create_by!(email: 'admin@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'admin'
  u.name = '管理者'
  u.terms_accepted_at = Time.current
  u.privacy_accepted_at = Time.current
end
puts "✅ 管理者アカウント作成: #{admin.email} (role: #{admin.role})"

# ========================================
# 2. デモ用招待コードの作成
# ========================================
# 一般ユーザーの登録には有効な招待コードが必須のため、デモ用のコードを用意する。
demo_invitation_code = InvitationCode.find_or_create_by!(code: 'DEMO2024') do |ic|
  ic.created_by = admin
  ic.max_uses = nil # 無制限
  ic.status = :active
  ic.memo = 'デモ環境用の招待コード（seedで作成）'
end
puts "✅ 招待コード作成: #{demo_invitation_code.code}"

# ========================================
# 3. お知らせの作成（管理者が作成者）
# ========================================
announcements_data = [
  {
    title: 'InkFolioデモ版へようこそ',
    body: 'この度はInkFolioデモ版をご利用いただきありがとうございます。' \
          '本システムは技術デモンストレーション・ポートフォリオ展示を目的としたデモ版です。' \
          '実在する患者・顧客の個人情報は入力しないでください。',
    severity: :info,
    published_at: 1.day.ago,
  },
  {
    title: 'デモアカウント情報',
    body: "デモユーザーアカウント:\nメールアドレス: demo@example.com\nパスワード: password123\n\n" \
          '上記アカウントで施術者として各種機能をお試しいただけます。',
    severity: :info,
    published_at: 2.days.ago,
  },
  {
    title: '主な機能のご紹介',
    body: "InkFolioでは以下の機能をご利用いただけます：\n\n" \
          "・患者管理（カルテ・問診票）\n・施術記録管理\n・売上・請求書管理\n" \
          "・施術場所管理\n・コストシート管理\n\nぜひ各機能をお試しください。",
    severity: :info,
    published_at: 3.days.ago,
  },
  {
    title: 'テストデータについて',
    body: '本デモ版に含まれるすべてのデータは架空のテストデータです。実在する個人・団体とは一切関係ありません。',
    severity: :warning,
    published_at: 4.days.ago,
  },
]

announcements_data.each_with_index do |data, index|
  Announcement.find_or_create_by!(title: data[:title]) do |a|
    a.author = admin
    a.body = data[:body]
    a.status = :published
    a.severity = data[:severity]
    a.published_at = data[:published_at]
    a.display_order = index
  end
end
puts "✅ お知らせ作成: #{Announcement.count}件"

# ========================================
# 4. デモユーザー（アートメイク施術者）の作成
# ========================================
demo_user = User.find_or_create_by!(email: 'demo@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'user'
  u.name = 'デモ施術者'
  u.terms_accepted_at = Time.current
  u.privacy_accepted_at = Time.current
  u.invitation_code_input = demo_invitation_code.code
end
puts "✅ デモユーザー作成: #{demo_user.email} (role: #{demo_user.role})"

# ========================================
# 5. 施術場所の作成
# ========================================
facilities_data = [
  { name: '青山美容クリニック', address: '東京都港区南青山1-1-1 青山ビル3F', phone: '03-1234-5678', billing_rate: 70 },
  { name: '表参道メディカルサロン', address: '東京都渋谷区神宮前5-2-3 表参道プラザ2F', phone: '03-2345-6789', billing_rate: 65 },
  { name: '銀座ビューティークリニック', address: '東京都中央区銀座4-3-2 銀座タワー5F', phone: '03-3456-7890', billing_rate: 75 },
]

facilities = facilities_data.map do |data|
  Facility.find_or_create_by!(user: demo_user, name: data[:name]) do |f|
    f.address = data[:address]
    f.phone = data[:phone]
    f.billing_rate = data[:billing_rate]
  end
end
puts "✅ 施術場所作成: #{Facility.where(user: demo_user).count}件"

# ========================================
# 6. コストシート（アートメイク用）の作成
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
# 7. 患者の作成（架空のテストデータ）
# ========================================
# NOTE: phone / email / address / emergency_contact は Active Record Encryption で暗号化される。
patients_data = [
  {
    name: '山田花子', date_of_birth: Date.new(1990, 5, 15), gender: :female,
    phone: '090-1234-5678', email: 'hanako.yamada@example.com',
    address: '東京都テスト区サンプル町1-1-1', emergency_contact: '090-0000-0001（配偶者）',
  },
  {
    name: '田中美咲', date_of_birth: Date.new(1985, 8, 22), gender: :female,
    phone: '090-2345-6789', email: 'misaki.tanaka@example.com',
    address: '東京都テスト区サンプル町2-2-2', emergency_contact: '090-0000-0002（家族）',
  },
  {
    name: '佐藤結衣', date_of_birth: Date.new(1995, 3, 10), gender: :female,
    phone: '090-3456-7890', email: 'yui.sato@example.com',
    address: '東京都テスト区サンプル町3-3-3', emergency_contact: '090-0000-0003（家族）',
  },
  {
    name: '鈴木愛', date_of_birth: Date.new(1988, 12, 5), gender: :female,
    phone: '090-4567-8901', email: 'ai.suzuki@example.com',
    address: '東京都テスト区サンプル町4-4-4', emergency_contact: '090-0000-0004（家族）',
  },
]

patients = patients_data.map do |data|
  Patient.find_or_create_by!(user: demo_user, email: data[:email]) do |p|
    p.name = data[:name]
    p.date_of_birth = data[:date_of_birth]
    p.gender = data[:gender]
    p.phone = data[:phone]
    p.address = data[:address]
    p.emergency_contact = data[:emergency_contact]
  end
end
puts "✅ 患者作成: #{Patient.where(user: demo_user).count}件"

# ========================================
# 8. カルテとコスト項目の作成
# ========================================
# NOTE: CostItem の total_price は before_validation で自動計算されるため指定不要。
medical_records_data = [
  {
    patient_index: 0, facility_index: 0, visit_date: 2.weeks.ago.to_date,
    treatment_content: '眉アートメイク（4D）初回施術',
    notes: <<~NOTES,
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
    items: [
      { name: '眉アートメイク（4D）', quantity: 1, unit_price: 100_000 },
      { name: '色素（ブラウン系）', quantity: 1, unit_price: 8000 },
      { name: '麻酔クリーム', quantity: 1, unit_price: 2000 },
      { name: '針（使い捨て）', quantity: 1, unit_price: 1500 },
      { name: 'グローブ', quantity: 1, unit_price: 500 },
    ],
  },
  {
    patient_index: 1, facility_index: 1, visit_date: 1.week.ago.to_date,
    treatment_content: 'アイライン上施術',
    notes: <<~NOTES,
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
    items: [
      { name: 'アイライン上', quantity: 1, unit_price: 50_000 },
      { name: '色素（ブラウン系）', quantity: 1, unit_price: 8000 },
      { name: '麻酔クリーム', quantity: 1, unit_price: 2000 },
      { name: '針（使い捨て）', quantity: 1, unit_price: 1500 },
    ],
  },
  {
    patient_index: 2, facility_index: 2, visit_date: 3.days.ago.to_date,
    treatment_content: '眉アートメイク（2D）初回施術',
    notes: <<~NOTES,
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
    items: [
      { name: '眉アートメイク（2D）', quantity: 1, unit_price: 60_000 },
      { name: '色素（ブラウン系）', quantity: 1, unit_price: 8000 },
      { name: '麻酔クリーム', quantity: 1, unit_price: 2000 },
      { name: '針（使い捨て）', quantity: 1, unit_price: 1500 },
      { name: 'グローブ', quantity: 1, unit_price: 500 },
    ],
  },
]

medical_records_data.each do |data|
  patient = patients[data[:patient_index]]
  facility = facilities[data[:facility_index]]
  next unless patient && facility

  record = MedicalRecord.find_or_create_by!(
    user: demo_user,
    patient: patient,
    facility: facility,
    visit_date: data[:visit_date]
  ) do |mr|
    mr.treatment_content = data[:treatment_content]
    mr.notes = data[:notes]
  end

  data[:items].each do |item|
    cost_sheet = CostSheet.find_by(user: demo_user, item_name: item[:name])
    next unless cost_sheet

    CostItem.find_or_create_by!(medical_record: record, cost_sheet: cost_sheet) do |ci|
      ci.item_name = cost_sheet.item_name
      ci.quantity = item[:quantity]
      ci.unit_price = item[:unit_price]
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
puts '  - 管理者アカウント: admin@example.com / password123'
puts '  - デモユーザー: demo@example.com / password123'
puts "  - 招待コード: #{demo_invitation_code.code}"
puts "  - お知らせ: #{Announcement.count}件"
puts "  - 施術場所: #{Facility.where(user: demo_user).count}件"
puts "  - コストシート: #{CostSheet.where(user: demo_user).count}件"
puts "  - 患者: #{Patient.where(user: demo_user).count}件"
puts "  - カルテ: #{MedicalRecord.where(user: demo_user).count}件"
