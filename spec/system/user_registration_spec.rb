# frozen_string_literal: true

require 'rails_helper'

# 新規登録はデモ環境として無効化しているが（Issue #64）、招待コード制の登録フロー自体は
# 実装済みのため、無効化を解除して検証する（無効化の挙動は disabled_account_links_spec.rb）。
RSpec.describe 'User Registration', type: :system, account_actions_enabled: true do
  let(:admin) { create(:user, :admin, create_invitation_code: false) }
  let!(:valid_code) { create(:invitation_code, created_by: admin, code: 'TESTCODE', status: :active) }

  describe '新規登録ページ' do
    before { visit new_user_registration_path }

    it 'ページが正しく表示される' do
      expect(page).to have_selector('img[alt="InkFolio"]')
      expect(page).to have_content('新規アカウント登録')
    end

    it 'フォームフィールドが表示される' do
      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')
      expect(page).to have_field('パスワード（確認）')
      expect(page).to have_field('user_invitation_code_input')
      expect(page).to have_field('user_terms_accepted')
      expect(page).to have_field('user_privacy_accepted')
    end

    it '招待コードフィールドにヘルプテキストが表示される' do
      expect(page).to have_content('招待コードは管理者から発行された6〜12文字の英数字です')
    end

    it '規約リンクが表示される' do
      expect(page).to have_link('利用規約', href: terms_path)
      expect(page).to have_link('プライバシーポリシー', href: privacy_path)
    end

    it '登録ボタンが表示される' do
      expect(page).to have_button('新規登録')
    end

    it 'ログインリンクが表示される' do
      expect(page).to have_link('ログイン', href: new_user_session_path)
    end

    it 'フッターに著作権表記が表示される' do
      expect(page).to have_content("© #{Time.current.year} InkFolio. All rights reserved.")
    end
  end

  describe '新規登録処理', :js do
    before do
      visit new_user_registration_path
    end

    context '正常系：有効な招待コードでの登録' do
      it '新規登録に成功してダッシュボードにリダイレクトされる' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'TESTCODE'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        expect do
          click_button '新規登録'
          sleep 1 # Deviseのリダイレクト待機
        end.to change(User, :count).by(1)

        expect(page).to have_current_path(user_dashboard_path)
        expect(page).to have_content('アカウント登録が完了しました')
      end

      it '招待コードの使用回数がインクリメントされる' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'TESTCODE'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        expect do
          click_button '新規登録'
          sleep 1
        end.to change { valid_code.reload.used_count }.by(1)
      end
    end

    context '異常系：無効な招待コード' do
      it '存在しない招待コードでエラーメッセージが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'INVALID99'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('有効な招待コードではありません')
        expect(page).to have_current_path(new_user_registration_path)
      end

      it '無効（inactive）な招待コードでエラーメッセージが表示される' do
        create(:invitation_code, :inactive, created_by: admin, code: 'INACTIVE1')

        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'INACTIVE1'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('無効な招待コードです')
        expect(page).to have_current_path(new_user_registration_path)
      end

      it '期限切れの招待コードでエラーメッセージが表示される' do
        create(:invitation_code, :expired, created_by: admin, code: 'EXPIRED99')

        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'EXPIRED99'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('有効期限が切れています')
        expect(page).to have_current_path(new_user_registration_path)
      end

      it '使用回数上限に達した招待コードでエラーメッセージが表示される' do
        create(:invitation_code, :max_uses_reached, created_by: admin, code: 'MAXOUT123')

        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'MAXOUT123'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('使用回数の上限に達しています')
        expect(page).to have_current_path(new_user_registration_path)
      end
    end

    context '異常系：招待コードなし' do
      it 'エラーメッセージが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        # 招待コードを入力しない
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('招待コードを入力してください')
        expect(page).to have_current_path(new_user_registration_path)
      end
    end

    context '異常系：規約同意なし' do
      it '利用規約未同意でエラーメッセージが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'TESTCODE'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        # 利用規約にチェックしない
        check 'user_privacy_accepted'

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('利用規約への同意が必要です')
        expect(page).to have_current_path(new_user_registration_path)
      end

      it 'プライバシーポリシー未同意でエラーメッセージが表示される' do
        fill_in 'メールアドレス', with: 'newuser@example.com'
        fill_in '招待コード', with: 'TESTCODE'
        fill_in 'パスワード', with: 'password123'
        fill_in 'パスワード（確認）', with: 'password123'
        check 'user_terms_accepted'
        # プライバシーポリシーにチェックしない

        click_button '新規登録'
        sleep 0.5

        expect(page).to have_content('プライバシーポリシーへの同意が必要です')
        expect(page).to have_current_path(new_user_registration_path)
      end
    end
  end
end
