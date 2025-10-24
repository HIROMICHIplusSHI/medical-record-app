# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication Flow', type: :system do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'ウェルカムページ' do
    before { visit root_path }

    it 'ウェルカムページが正しく表示される' do
      expect(page).to have_selector('img[alt="InkFolio"]')
      expect(page).to have_content('アートメイク施術者のための')
      expect(page).to have_content('ポートフォリオ＆業務管理システム')
    end

    it 'ログインフォームが表示される' do
      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')
      expect(page).to have_button('ログイン')
      expect(page).to have_content('ログイン状態を保持')
    end

    it 'フィーチャータグが表示される' do
      expect(page).to have_content('施術ポートフォリオ')
      expect(page).to have_content('売上・請求管理')
      expect(page).to have_content('データ暗号化')
    end

    it '新規登録リンクが表示される' do
      expect(page).to have_link('新規登録', href: new_user_registration_path)
    end

    it 'パスワードを忘れたリンクが表示される' do
      expect(page).to have_link('パスワードを忘れた？', href: new_user_password_path)
    end

    it 'フッターに著作権表記が表示される' do
      expect(page).to have_content("© #{Time.current.year} InkFolio. All rights reserved.")
    end
  end

  describe 'ウェルカムページからのログイン', :js do
    before do
      user # ユーザーを作成
      visit root_path
    end

    context '正しい認証情報の場合' do
      it 'ログインに成功してダッシュボードにリダイレクトされる' do
        fill_in 'メールアドレス', with: 'test@example.com'
        fill_in 'パスワード', with: 'password123'
        click_button 'ログイン'

        expect(page).to have_current_path(user_dashboard_path)
        expect(page).to have_content('ダッシュボード')
        expect(page).to have_content('InkFolioへようこそ')
      end

      it 'ログイン状態を保持するチェックボックスが機能する' do
        fill_in 'メールアドレス', with: 'test@example.com'
        fill_in 'パスワード', with: 'password123'
        check 'ログイン状態を保持'
        click_button 'ログイン'

        expect(page).to have_current_path(user_dashboard_path)
      end
    end

    context '誤った認証情報の場合' do
      it 'エラーメッセージが表示される' do
        fill_in 'メールアドレス', with: 'test@example.com'
        fill_in 'パスワード', with: 'wrong_password'
        click_button 'ログイン'

        # Deviseの翻訳が不足している場合も考慮
        expect(page).to have_content('invalid').or have_content('メールアドレスまたはパスワードが違います')
      end
    end
  end

  describe 'ログインページ', :js do
    before { visit new_user_session_path }

    it 'ログインページが正しく表示される' do
      expect(page).to have_selector('img[alt="InkFolio"]')
      expect(page).to have_content('アカウントにログイン')
      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')
      expect(page).to have_button('ログイン')
    end

    it '新規登録リンクが表示される' do
      expect(page).to have_link('新規登録')
    end

    it 'ログインに成功してダッシュボードにリダイレクトされる' do
      user # ユーザーを作成

      fill_in 'メールアドレス', with: 'test@example.com'
      fill_in 'パスワード', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_current_path(user_dashboard_path)
      expect(page).to have_content('ダッシュボード')
    end
  end

  describe '新規登録ページ', :js do
    before { visit new_user_registration_path }

    it '新規登録ページが正しく表示される' do
      expect(page).to have_selector('img[alt="InkFolio"]')
      expect(page).to have_content('新規アカウント登録')
      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')
      expect(page).to have_field('パスワード（確認）')
      expect(page).to have_button('新規登録')
    end

    it 'ログインリンクが表示される' do
      expect(page).to have_link('ログイン')
    end

    it '新規登録に成功してダッシュボードにリダイレクトされる' do
      fill_in 'メールアドレス', with: 'newuser@example.com'
      fill_in 'パスワード', with: 'password123'
      fill_in 'パスワード（確認）', with: 'password123'
      click_button '新規登録'

      expect(page).to have_current_path(user_dashboard_path)
      expect(page).to have_content('ダッシュボード')
      # Deviseの翻訳が不足している場合も考慮
      expect(page).to have_content('signed_up').or have_content('アカウント登録が完了しました')
    end

    context 'バリデーションエラーの場合' do
      it 'パスワードが短すぎる場合エラーが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in 'パスワード', with: '123'
        fill_in 'パスワード（確認）', with: '123'
        click_button '新規登録'

        # エラーメッセージの表示を確認（日本語または英語）
        expect(page).to have_content('6文字以上').or have_content('is too short')
      end

      it 'パスワードが一致しない場合エラーが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'different_password'
        click_button '新規登録'

        # エラーメッセージの表示を確認（日本語または英語）
        expect(page).to have_content('一致しません').or have_content('doesn\'t match')
      end
    end
  end

  describe 'ログアウトフロー', :js do
    before do
      sign_in user
      visit user_dashboard_path
    end

    it 'ログアウト後にウェルカムページにリダイレクトされる' do
      # ユーザードロップダウンを開く
      find('#user-menu-button').click
      # ログアウトリンクをクリック
      click_link 'ログアウト'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('アートメイク施術者のための')
      expect(page).to have_field('メールアドレス')
      # Deviseの翻訳が不足している場合も考慮
      expect(page).to have_content('signed_out').or have_content('ログアウトしました')
    end
  end

  describe 'ナビゲーションフロー', :js do
    context '未認証ユーザーの場合' do
      it 'ウェルカムページから新規登録ページに遷移できる' do
        visit root_path
        click_link '新規登録'

        expect(page).to have_current_path(new_user_registration_path)
        expect(page).to have_content('新規アカウント登録')
      end

      it '新規登録ページからログインページに遷移できる' do
        visit new_user_registration_path
        click_link 'ログイン'

        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('アカウントにログイン')
      end

      it 'ログインページから新規登録ページに遷移できる' do
        visit new_user_session_path
        click_link '新規登録'

        expect(page).to have_current_path(new_user_registration_path)
        expect(page).to have_content('新規アカウント登録')
      end
    end

    context '認証済みユーザーの場合' do
      before { sign_in user }

      it 'ルートパスにアクセスするとダッシュボードにリダイレクトされる' do
        visit root_path

        expect(page).to have_current_path(user_dashboard_path)
        expect(page).to have_content('ダッシュボード')
      end

      it 'ヘッダーのロゴクリックでダッシュボードに戻る' do
        visit patients_path

        # ヘッダー内のロゴをクリック
        within('header') do
          find('img[alt="InkFolio"]').click
        end

        expect(page).to have_current_path(user_dashboard_path)
        expect(page).to have_content('ダッシュボード')
      end
    end
  end

  describe 'デザイン統一性' do
    it 'ウェルカムページのスタイルが正しい' do
      visit root_path

      # 背景グラデーション
      expect(page).to have_selector('.bg-gradient-to-br')
      # セミトランスペアレントカード
      expect(page).to have_selector('.bg-white\\/80')
      # 角丸ボーダー
      expect(page).to have_selector('.rounded-2xl')
    end

    it 'ログインページのスタイルがウェルカムページと統一されている' do
      visit new_user_session_path

      expect(page).to have_selector('.bg-gradient-to-br')
      expect(page).to have_selector('.bg-white\\/80')
      expect(page).to have_selector('.rounded-2xl')
    end

    it '新規登録ページのスタイルがウェルカムページと統一されている' do
      visit new_user_registration_path

      expect(page).to have_selector('.bg-gradient-to-br')
      expect(page).to have_selector('.bg-white\\/80')
      expect(page).to have_selector('.rounded-2xl')
    end
  end
end
