require 'rails_helper'

RSpec.describe 'お問い合わせワークフロー', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'お問い合わせ一覧画面' do
    context 'お問い合わせが存在しない場合' do
      it 'メッセージが表示される', js: true do
        visit inquiries_path

        expect(page).to have_content('お問い合わせ')
        expect(page).to have_content('まだお問い合わせはありません。')
      end
    end

    context 'お問い合わせが存在する場合' do
      let!(:inquiries) { create_list(:inquiry, 3, user: user) }

      it 'お問い合わせ一覧が表示される', js: true do
        visit inquiries_path

        expect(page).to have_content('お問い合わせ')
        expect(page).to have_selector('tbody tr', count: 3)
      end

      it 'ステータスバッジが表示される', js: true do
        create(:inquiry, user: user, status: :open)
        create(:inquiry, :in_progress, user: user)
        create(:inquiry, :closed, user: user)

        visit inquiries_path

        expect(page).to have_content('未対応')
        expect(page).to have_content('対応中')
        expect(page).to have_content('対応完了')
      end

      it '新規作成ボタンが表示される', js: true do
        visit inquiries_path

        expect(page).to have_link('新規お問い合わせ', href: new_inquiry_path)
      end
    end
  end

  describe 'お問い合わせ作成フロー' do
    it 'お問い合わせを作成できる', js: true do
      visit inquiries_path

      click_link '新規お問い合わせ'
      expect(page).to have_current_path(new_inquiry_path)
      expect(page).to have_content('新規お問い合わせ')

      fill_in '件名', with: 'システムに関する質問'
      fill_in 'お問い合わせ内容', with: 'ログイン機能について教えてください。'

      click_button '送信'

      expect(page).to have_content('お問い合わせを送信しました')
      expect(page).to have_content('システムに関する質問')
      expect(page).to have_content('ログイン機能について教えてください')
    end

    it 'バリデーションエラーが表示される', js: true do
      visit new_inquiry_path

      fill_in '件名', with: ''
      fill_in 'お問い合わせ内容', with: ''

      click_button '送信'

      # エラー時は new 画面に留まる
      expect(page).to have_current_path('/inquiries/new', ignore_query: true)
      expect(page).to have_content('新規お問い合わせ')
    end
  end

  describe 'お問い合わせ詳細画面' do
    let!(:inquiry) { create(:inquiry, user: user, subject: 'テスト件名') }
    let!(:messages) { create_list(:inquiry_message, 3, inquiry: inquiry, user: user) }

    it '詳細情報が表示される', js: true do
      visit inquiry_path(inquiry)

      expect(page).to have_content(inquiry.subject)
      expect(page).to have_content('未対応')
      # 詳細情報セクション、メッセージ履歴セクション、返信フォームセクション
      expect(page).to have_selector('div.bg-white.shadow-md.rounded', minimum: 3)
    end

    it 'メッセージが古い順に表示される', js: true do
      visit inquiry_path(inquiry)

      # メッセージ履歴セクション内のメッセージを取得
      message_section = page.find('h2', text: 'メッセージ履歴').find(:xpath, '..')
      message_bodies = message_section.all('div.whitespace-pre-wrap')

      # 最初のメッセージが最初に表示される
      expect(message_bodies.first.text).to include(messages.first.body)
    end

    it '一覧に戻るボタンが表示される', js: true do
      visit inquiry_path(inquiry)

      expect(page).to have_link('一覧に戻る', href: inquiries_path)
    end
  end

  describe 'メッセージ返信機能' do
    let!(:inquiry) { create(:inquiry, user: user) }
    let!(:message) { create(:inquiry_message, inquiry: inquiry, user: user) }

    it 'メッセージを追加できる', js: true do
      visit inquiry_path(inquiry)

      fill_in '本文', with: '追加のメッセージです。'
      click_button '送信'

      expect(page).to have_content('メッセージを送信しました')
      expect(page).to have_content('追加のメッセージです。')
    end

    it 'バリデーションエラーが表示される', js: true do
      visit inquiry_path(inquiry)

      fill_in '本文', with: ''
      click_button '送信'

      # エラー時は show 画面に留まり、エラーメッセージが表示される
      expect(page).to have_content('本文を入力してください')
    end
  end

  describe '他のユーザーのお問い合わせにアクセス' do
    let(:other_user) { create(:user) }
    let!(:other_inquiry) { create(:inquiry, user: other_user) }

    it 'アクセスできずリダイレクトされる', js: true do
      visit inquiry_path(other_inquiry)

      expect(page).to have_current_path(inquiries_path)
      expect(page).to have_content('お問い合わせが見つかりません')
    end
  end

  describe 'ナビゲーション確認' do
    it 'ヘッダーにお問い合わせリンクが表示される', js: true do
      visit user_dashboard_path

      # デスクトップナビゲーション
      within('nav.hidden.md\\:flex') do
        expect(page).to have_link('お問い合わせ', href: inquiries_path)
      end
    end
  end
end
