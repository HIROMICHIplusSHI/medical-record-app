require 'rails_helper'

RSpec.describe 'Pages', type: :system do
  describe '利用規約ページ', js: true do
    it '利用規約が表示される' do
      visit terms_path

      expect(page).to have_selector('h1', text: 'ベータ版利用規約')
      expect(page).to have_content('InkFolio')
      expect(page).to have_content('本アプリは補助ツールです')
      expect(page).to have_content('医療法上の正式な診療録（カルテ）ではありません')
    end

    it '未認証でもアクセスできる' do
      visit terms_path

      expect(page).to have_selector('h1', text: 'ベータ版利用規約')
      expect(page).not_to have_content('ログイン')
    end

    it '主要セクションが表示される' do
      visit terms_path

      expect(page).to have_content('1. ベータ版について')
      expect(page).to have_content('2. 本アプリの目的と性質')
      expect(page).to have_content('5. データの取り扱い')
      expect(page).to have_content('7. 免責事項')
      expect(page).to have_content('14. 最後に大切なこと')
    end

    it '警告メッセージが表示される' do
      visit terms_path

      # ベータ版警告
      expect(page).to have_content('重要：本アプリは無料で提供されるベータ版であり、継続的な提供を保証するものではありません')

      # 施設記録必須警告
      expect(page).to have_content('本アプリに記録したかどうかに関わらず、施設の正式な電子カルテへの記録は必ず行ってください')

      # データ消失警告
      expect(page).to have_content('大切なデータは必ず別途保存してください。データ消失について運営者は一切責任を負いません')

      # 免責警告
      expect(page).to have_content('本アプリは「現状有姿」で提供され、いかなる保証もありません')
    end
  end

  describe 'プライバシーポリシーページ', js: true do
    it 'プライバシーポリシーが表示される' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
      expect(page).to have_content('InkFolio')
      expect(page).to have_content('個人情報保護法')
    end

    it '未認証でもアクセスできる' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
      # 未認証でもページが表示されることを確認（認証エラーがないこと）
      expect(page).not_to have_content('アカウント登録')
    end

    it '主要セクションが表示される' do
      visit privacy_path

      expect(page).to have_content('第1条（個人情報の定義）')
      expect(page).to have_content('第2条（本ポリシーの適用範囲）')
      expect(page).to have_content('第5条（顧客情報の取扱い）')
      expect(page).to have_content('第6条（要配慮個人情報の取扱い）')
      expect(page).to have_content('第9条（個人情報の安全管理措置）')
      expect(page).to have_content('第12条（個人情報の開示、訂正、利用停止等）')
    end

    it '利用者情報の取得項目が表示される' do
      visit privacy_path

      # 登録情報
      expect(page).to have_content('1. 登録情報')
      expect(page).to have_content('氏名、メールアドレス、電話番号')

      # 決済情報
      expect(page).to have_content('2. 決済情報')

      # 利用履歴情報
      expect(page).to have_content('3. 利用履歴情報')
      expect(page).to have_content('Cookie情報、端末情報')
    end

    it '安全管理措置が表示される' do
      visit privacy_path

      expect(page).to have_content('1. 技術的安全管理措置')
      expect(page).to have_content('SSL/TLS暗号化通信の使用')

      expect(page).to have_content('2. 組織的安全管理措置')
      expect(page).to have_content('個人情報取扱規程の策定')

      expect(page).to have_content('3. 物理的安全管理措置')
      expect(page).to have_content('サーバー設備の施錠管理')

      expect(page).to have_content('4. 人的安全管理措置')
      expect(page).to have_content('秘密保持契約の締結')
    end

    it 'お問い合わせ窓口が表示される' do
      visit privacy_path

      expect(page).to have_content('個人情報に関するお問い合わせ窓口')
      expect(page).to have_content('inkfolio.sup@gmail.com')
      expect(page).to have_content('平日10:00〜17:00')
    end
  end
end
