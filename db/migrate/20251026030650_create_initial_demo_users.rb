class CreateInitialDemoUsers < ActiveRecord::Migration[7.2]
  def up
    # 本番環境でのみ実行（開発・テスト環境では既存データがあるため）
    return unless Rails.env.production?

    # 管理者アカウント作成
    User.find_or_create_by!(email: 'admin@example.com') do |user|
      user.password = ENV.fetch('ADMIN_PASSWORD', 'AdminDemo2024!')
      user.password_confirmation = ENV.fetch('ADMIN_PASSWORD', 'AdminDemo2024!')
      user.role = :admin
      user.name = '管理者'
    end

    # 通常ユーザーアカウント作成
    User.find_or_create_by!(email: 'user@example.com') do |user|
      user.password = ENV.fetch('USER_PASSWORD', 'UserDemo2024!')
      user.password_confirmation = ENV.fetch('USER_PASSWORD', 'UserDemo2024!')
      user.role = :user
      user.name = 'デモユーザー'
    end
  end

  def down
    # 本番環境でのみ削除
    return unless Rails.env.production?

    User.find_by(email: 'admin@example.com')&.destroy
    User.find_by(email: 'user@example.com')&.destroy
  end
end
