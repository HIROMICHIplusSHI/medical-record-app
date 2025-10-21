namespace :admin do
  desc '管理者ユーザーを作成'
  task create: :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || SecureRandom.alphanumeric(16)

    # 既存チェック
    if User.exists?(email: email)
      puts "管理者ユーザーは既に存在します: #{email}"
      exit
    end

    begin
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password
      )

      # ロール変更を許可してから管理者に昇格
      user.allow_role_change!
      user.admin!

      puts '管理者を作成しました:'
      puts "  Email: #{email}"
      puts "  Password: #{password}" unless ENV['ADMIN_PASSWORD']
      puts "\n重要: パスワードを安全な場所に保存してください。"
    rescue ActiveRecord::RecordInvalid => e
      puts 'エラー: 管理者の作成に失敗しました'
      puts e.message
      exit 1
    end
  end

  desc '最初の管理者ユーザーを対話的に作成'
  task create_interactive: :environment do
    if User.admin.exists?
      puts '既に管理者ユーザーが存在します。'
      puts '既存の管理者:'
      User.admin.each do |admin|
        puts "  - #{admin.email}"
      end
      exit
    end

    require 'io/console'

    print 'メールアドレス: '
    email = $stdin.gets.chomp

    print 'パスワード: '
    password = $stdin.noecho(&:gets).chomp
    puts

    print 'パスワード（確認）: '
    password_confirmation = $stdin.noecho(&:gets).chomp
    puts

    if password != password_confirmation
      puts 'エラー: パスワードが一致しません'
      exit 1
    end

    begin
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password_confirmation
      )

      # ロール変更を許可してから管理者に昇格
      user.allow_role_change!
      user.admin!

      puts "\n管理者を作成しました:"
      puts "  Email: #{email}"
    rescue ActiveRecord::RecordInvalid => e
      puts "\nエラー: 管理者の作成に失敗しました"
      puts e.message
      exit 1
    end
  end

  desc '全管理者ユーザーを一覧表示'
  task list: :environment do
    admins = User.admin.order(created_at: :asc)

    if admins.empty?
      puts '管理者ユーザーが存在しません。'
      puts '作成するには: bundle exec rake admin:create_interactive'
      exit
    end

    puts '管理者ユーザー一覧:'
    admins.each_with_index do |admin, index|
      puts "  #{index + 1}. #{admin.email} (作成日: #{admin.created_at.strftime('%Y/%m/%d')})"
    end
    puts "\n合計: #{admins.count}人"
  end
end
