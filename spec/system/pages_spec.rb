require 'rails_helper'

RSpec.describe 'Pages', type: :system do
  describe '利用規約ページ', js: true do
    it '利用規約が表示される' do
      visit terms_path

      expect(page).to have_selector('h1', text: 'デモ版利用規約')
      expect(page).to have_content('InkFolio')
      expect(page).to have_content('技術デモンストレーション・ポートフォリオ展示を目的としたデモ版')
    end

    it '未認証でもアクセスできる' do
      visit terms_path

      expect(page).to have_selector('h1', text: 'デモ版利用規約')
      expect(page).not_to have_content('ログイン')
    end

    it '主要セクションが表示される' do
      visit terms_path

      expect(page).to have_content('第1条（本規約の適用）')
      expect(page).to have_content('第2条（デモ版の位置づけ）')
      expect(page).to have_content('第4条（禁止事項）')
      expect(page).to have_content('第5条（データの取扱い）')
      expect(page).to have_content('第7条（免責事項）')
    end

    it '警告メッセージが表示される' do
      visit terms_path

      # デモ版警告
      expect(page).to have_content('本デモシステムは、医療行為・美容施術に関する実際の業務には使用しないでください')

      # 個人情報入力禁止警告
      expect(page).to have_content('実在する患者・顧客の個人情報を入力する行為')

      # 免責警告
      expect(page).to have_content('本デモシステムは「現状有姿（AS IS）」で提供されます')

      # ポートフォリオ作品であることの明記
      expect(page).to have_content('開発者の技術スキルを証明するためのポートフォリオ作品')
    end

    it 'テストデータの例が表示される' do
      visit terms_path

      expect(page).to have_content('テストデータの例')
      expect(page).to have_content('山田太郎、田中花子')
      expect(page).to have_content('000-0000-0000')
      expect(page).to have_content('test@example.com')
    end
  end

  describe 'プライバシーポリシーページ', js: true do
    it 'プライバシーポリシーが表示される' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー（デモ版）')
      expect(page).to have_content('InkFolio')
      expect(page).to have_content('技術デモンストレーション・ポートフォリオ展示を目的としたデモ版')
    end

    it '未認証でもアクセスできる' do
      visit privacy_path

      expect(page).to have_selector('h1', text: 'プライバシーポリシー（デモ版）')
      # 未認証でもページが表示されることを確認（認証エラーがないこと）
      expect(page).not_to have_content('アカウント登録')
    end

    it '主要セクションが表示される' do
      visit privacy_path

      expect(page).to have_content('第1条（本ポリシーの適用）')
      expect(page).to have_content('第2条（デモ版における情報の取扱い）')
      expect(page).to have_content('第3条（取得する情報）')
      expect(page).to have_content('第6条（セキュリティ対策）')
      expect(page).to have_content('第10条（免責事項）')
      expect(page).to have_content('第12条（個人情報保護法との関係）')
    end

    it '個人情報入力禁止の警告が表示される' do
      visit privacy_path

      expect(page).to have_content('本デモシステムには、実在する個人の情報を入力しないでください')
      expect(page).to have_content('実在する患者・顧客の個人情報を入力した場合、個人情報保護法違反となる可能性があります')
      expect(page).to have_content('実際の業務で個人情報を取り扱う場合は、個人情報保護法に準拠した正式なシステムを使用してください')
    end

    it '取得する情報が表示される' do
      visit privacy_path

      # アカウント情報
      expect(page).to have_content('3-1. アカウント情報')
      expect(page).to have_content('メールアドレス（認証目的）')
      expect(page).to have_content('パスワード（ハッシュ化して保存）')

      # 入力データ
      expect(page).to have_content('3-2. 入力データ')
      expect(page).to have_content('架空のテストデータ')

      # 利用履歴情報
      expect(page).to have_content('3-3. 利用履歴情報')
      expect(page).to have_content('Cookie情報')
    end

    it 'セキュリティ対策が表示される' do
      visit privacy_path

      expect(page).to have_content('SSL/TLS暗号化通信の使用')
      expect(page).to have_content('パスワードのハッシュ化保存（bcrypt）')
      expect(page).to have_content('Active Record Encryption による機密データの暗号化')
      expect(page).to have_content('セキュリティの限界について')
    end

    it 'お問い合わせ窓口が表示される' do
      visit privacy_path

      expect(page).to have_content('お問い合わせ')
      expect(page).to have_content('inkfolio.sup@gmail.com')
      expect(page).to have_content('平日10:00〜17:00')
      expect(page).to have_content('本デモシステムはポートフォリオ作品のため、サポート対応は限定的です')
    end
  end
end
