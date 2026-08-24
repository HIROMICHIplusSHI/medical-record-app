# frozen_string_literal: true

require 'rails_helper'

# js: true は実ブラウザからのアクセスでテストデータが見えるようにするために必須
# （DatabaseCleaner が truncation 戦略へ切り替わる。spec/rails_helper.rb 参照）
RSpec.describe 'デモログイン', type: :system, js: true do
  let!(:demo_user) do
    create(:user, email: DemoSession::DEMO_EMAIL, name: 'デモ施術者')
  end

  # system spec ではブラウザからの要求を別スレッドの Rails サーバーが処理するため、
  # スタブではなく環境変数そのものを差し替える。
  around do |example|
    original = ENV.fetch('DEMO_LOGIN_ENABLED', nil)
    ENV['DEMO_LOGIN_ENABLED'] = demo_login_enabled
    example.run
    ENV['DEMO_LOGIN_ENABLED'] = original
  end

  context 'デモ機能が有効な場合' do
    let(:demo_login_enabled) { 'true' }

    it 'ウェルカムページのボタンからログインでき、ダッシュボードが表示されること' do
      visit root_path

      expect(page).to have_content('ポートフォリオとして公開中のデモ環境です')

      click_button 'デモアカウントでログイン'

      expect(page).to have_current_path(user_dashboard_path)
      expect(page).to have_content('デモアカウントでログインしました。')
    end

    it 'ログイン画面のボタンからもログインできること' do
      visit new_user_session_path

      click_button 'デモアカウントでログイン'

      expect(page).to have_current_path(user_dashboard_path)
    end

    it 'ログイン後に施術者向けの機能へアクセスできること' do
      visit root_path
      click_button 'デモアカウントでログイン'

      visit patients_path

      expect(page).to have_current_path(patients_path)
    end
  end

  context 'デモ機能が無効な場合' do
    let(:demo_login_enabled) { 'false' }

    it 'デモログインボタンが表示されないこと' do
      visit root_path

      expect(page).to have_button('ログイン')
      expect(page).to have_no_button('デモアカウントでログイン')
    end
  end

  describe '資格情報の非掲示（Issue #64）' do
    let(:demo_login_enabled) { 'true' }

    it 'ウェルカムページにクローズドベータの案内が残っていないこと' do
      visit root_path

      expect(page).to have_no_content('クローズドベータ')
    end
  end
end
