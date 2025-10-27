require 'rails_helper'

RSpec.describe 'Pages', type: :system do
  describe '利用規約ページ', js: true do
    it '利用規約が表示される' do
      visit terms_path

      expect(page).to have_selector('h1', text: '電子カルテシステム利用規約')
      expect(page).to have_content('InkFolio')
    end

    it '未認証でもアクセスできる' do
      visit terms_path

      expect(page).to have_selector('h1', text: '電子カルテシステム利用規約')
      expect(page).not_to have_content('ログイン')
    end

    it '主要セクションが表示される' do
      visit terms_path

      expect(page).to have_content('第1条（適用）')
      expect(page).to have_content('第3条（本サービスの性質）')
      expect(page).to have_content('第8条（禁止事項）')
      expect(page).to have_content('第12条（免責事項）')
    end
  end

  describe 'プライバシーポリシーページ', js: true do
    it 'プライバシーポリシーが表示される' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
      expect(page).to have_content('InkFolio')
    end

    it '未認証でもアクセスできる' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
      expect(page).not_to have_content('アカウント登録')
    end

    it '主要セクションが表示される' do
      visit privacy_path

      expect(page).to have_content('第1条（個人情報の定義）')
      expect(page).to have_content('第3条（利用者情報の取得）')
      expect(page).to have_content('第9条（個人情報の安全管理措置）')
      expect(page).to have_content('第12条（個人情報の開示、訂正、利用停止等）')
    end

    it '利用者の義務が表示される' do
      visit privacy_path

      expect(page).to have_content('利用者の義務')
      expect(page).to have_content('顧客から適切な同意を取得すること')
      expect(page).to have_content('個人情報保護法その他関連法令を遵守すること')
    end

    it 'お問い合わせ窓口が表示される' do
      visit privacy_path

      expect(page).to have_content('お問い合わせ')
      expect(page).to have_content('inkfolio.sup@gmail.com')
    end
  end
end
