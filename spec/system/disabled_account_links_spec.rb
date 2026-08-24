# frozen_string_literal: true

require 'rails_helper'

# js: true は実ブラウザからのアクセスでテストデータが見えるようにするために必須
# （DatabaseCleaner が truncation 戦略へ切り替わる。spec/rails_helper.rb 参照）
RSpec.describe 'アカウント操作リンクの無効化', type: :system, js: true do
  shared_examples 'アカウント操作が押せない画面' do
    it '新規登録・パスワード再設定がリンクではなく無効表示になっていること' do
      visit path

      expect(page).to have_content('新規登録')
      expect(page).to have_content('パスワードの再設定')
      expect(page).to have_content('デモ環境のため無効です')

      expect(page).to have_no_link('新規登録')
      expect(page).to have_no_link('パスワードの再設定')
      expect(page).to have_no_link('パスワードを忘れた？')
    end

    it 'ログインフォーム自体は従来どおり使えること' do
      visit path

      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')
      expect(page).to have_button('ログイン')
    end
  end

  describe 'トップページ' do
    let(:path) { root_path }

    it_behaves_like 'アカウント操作が押せない画面'
  end

  describe 'ログイン画面' do
    let(:path) { new_user_session_path }

    it_behaves_like 'アカウント操作が押せない画面'
  end

  describe 'URL 直打ち' do
    it '新規登録画面へアクセスするとログイン画面へ案内されること' do
      visit new_user_registration_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('デモ環境のため、この機能は無効です')
    end

    it 'パスワード再設定画面へアクセスするとログイン画面へ案内されること' do
      visit new_user_password_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('デモ環境のため、この機能は無効です')
    end
  end
end
