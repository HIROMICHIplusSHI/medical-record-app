require 'rails_helper'

RSpec.describe 'Admin Inquiries Management', type: :system do
  let(:admin_user) { create(:user, :admin) }
  let(:normal_user) { create(:user) }

  before do
    sign_in admin_user
  end

  describe 'お問い合わせ一覧画面' do
    let!(:open_inquiry) { create(:inquiry, user: normal_user, status: :open, subject: '未対応のお問い合わせ') }
    let!(:in_progress_inquiry) do
      create(:inquiry, :in_progress, user: normal_user, subject: '対応中のお問い合わせ')
    end
    let!(:closed_inquiry) { create(:inquiry, :closed, user: normal_user, subject: '完了したお問い合わせ') }

    it 'お問い合わせ一覧が表示される', js: true do
      visit admin_inquiries_path

      expect(page).to have_content('お問い合わせ管理')
      expect(page).to have_selector('.card', count: 3)
    end

    it 'お問い合わせ情報が正しく表示される', js: true do
      visit admin_inquiries_path

      # 件名
      expect(page).to have_content(open_inquiry.subject)
      expect(page).to have_content(in_progress_inquiry.subject)
      expect(page).to have_content(closed_inquiry.subject)

      # ステータスバッジ（badge-primary, badge-warning, badge-ghostクラスを使用）
      expect(page).to have_selector('.badge-primary', text: '未対応')
      expect(page).to have_selector('.badge-warning', text: '対応中')
      expect(page).to have_selector('.badge-ghost', text: '対応完了')
    end

    it 'ユーザー情報が表示される', js: true do
      visit admin_inquiries_path

      expect(page).to have_content(normal_user.name)
    end
  end

  describe 'ステータスフィルタリング機能' do
    let!(:open_inquiry) { create(:inquiry, user: normal_user, status: :open, subject: '未対応') }
    let!(:in_progress_inquiry) { create(:inquiry, :in_progress, user: normal_user, subject: '対応中') }
    let!(:closed_inquiry) { create(:inquiry, :closed, user: normal_user, subject: '完了') }

    it '未対応でフィルタできる', js: true do
      visit admin_inquiries_path

      select '未対応', from: 'status'
      click_button 'フィルター'

      expect(page).to have_content('未対応')
      expect(page).not_to have_content('対応中のお問い合わせ') # 件名でチェック
      expect(page).not_to have_content('完了したお問い合わせ') # 件名でチェック
    end

    it '対応中でフィルタできる', js: true do
      visit admin_inquiries_path

      select '対応中', from: 'status'
      click_button 'フィルター'

      expect(page).to have_content('対応中')
      expect(page).not_to have_content('未対応のお問い合わせ') # 件名でチェック
      expect(page).not_to have_content('完了したお問い合わせ') # 件名でチェック
    end

    it '対応完了でフィルタできる', js: true do
      visit admin_inquiries_path

      select '対応完了', from: 'status'
      click_button 'フィルター'

      expect(page).to have_content('完了')
      expect(page).not_to have_content('未対応のお問い合わせ') # 件名でチェック
      expect(page).not_to have_content('対応中のお問い合わせ') # 件名でチェック
    end
  end

  describe 'お問い合わせ詳細画面' do
    let!(:inquiry) { create(:inquiry, user: normal_user, subject: 'テスト件名') }
    let!(:user_message) { create(:inquiry_message, inquiry: inquiry, user: normal_user, body: 'ユーザーからの質問') }

    it '詳細情報が正しく表示される', js: true do
      visit admin_inquiry_path(inquiry)

      expect(page).to have_content(inquiry.subject)
      expect(page).to have_content('ユーザーからの質問')
    end

    it 'ステータスバッジが表示される', js: true do
      visit admin_inquiry_path(inquiry)

      # 未対応バッジの確認（badge-primaryクラス）
      status_badge = page.find('.badge-primary', text: '未対応')
      expect(status_badge).to be_present
    end

    it 'ステータス更新フォームが表示される', js: true do
      visit admin_inquiry_path(inquiry)

      expect(page).to have_select('inquiry[status]')
      expect(page).to have_button('更新')
    end

    it '一覧に戻るボタンが表示される', js: true do
      visit admin_inquiry_path(inquiry)

      expect(page).to have_link('一覧に戻る', href: admin_inquiries_path)
    end
  end

  describe 'ステータス更新機能' do
    let!(:inquiry) { create(:inquiry, user: normal_user, status: :open) }

    it 'ステータスを対応中に更新できる', js: true do
      visit admin_inquiry_path(inquiry)

      select '対応中', from: 'inquiry[status]'
      click_button '更新'

      expect(page).to have_content('ステータスを更新しました')
      expect(page).to have_selector('.badge-warning', text: '対応中')
    end

    it 'ステータスを対応完了に更新できる', js: true do
      visit admin_inquiry_path(inquiry)

      select '対応完了', from: 'inquiry[status]'
      click_button '更新'

      expect(page).to have_content('ステータスを更新しました')
      expect(page).to have_selector('.badge-ghost', text: '対応完了')
    end
  end

  describe '管理者メッセージ返信機能' do
    let!(:inquiry) { create(:inquiry, user: normal_user) }
    let!(:user_message) { create(:inquiry_message, inquiry: inquiry, user: normal_user) }

    it '管理者がメッセージを送信できる', js: true do
      visit admin_inquiry_path(inquiry)

      fill_in '本文', with: '管理者からの返信です。'
      click_button '返信'

      expect(page).to have_content('返信しました')
      expect(page).to have_content('管理者からの返信です。')
    end

    it '管理者メッセージは視覚的に区別される', js: true do
      create(:inquiry_message, inquiry: inquiry, user: admin_user, body: '管理者メッセージ')

      visit admin_inquiry_path(inquiry)

      # 管理者メッセージはbg-accent/10背景を持つカード
      admin_message_card = page.find('.card.bg-accent\\/10', text: '管理者メッセージ')
      expect(admin_message_card).to be_present

      # 管理者バッジも確認
      expect(admin_message_card).to have_selector('.badge-accent', text: '管理者')
    end

    it 'バリデーションエラーが表示される', js: true do
      visit admin_inquiry_path(inquiry)

      fill_in '本文', with: ''
      click_button '返信'

      expect(page).to have_content('本文を入力してください')
    end
  end

  describe 'メッセージ表示順序' do
    let!(:inquiry) { create(:inquiry, user: normal_user) }
    let!(:first_message) do
      create(:inquiry_message, inquiry: inquiry, user: normal_user, body: '最初のメッセージ', created_at: 1.hour.ago)
    end
    let!(:second_message) do
      create(:inquiry_message, inquiry: inquiry, user: admin_user, body: '2番目のメッセージ', created_at: 30.minutes.ago)
    end
    let!(:third_message) do
      create(:inquiry_message, inquiry: inquiry, user: normal_user, body: '3番目のメッセージ', created_at: Time.current)
    end

    it 'メッセージが古い順に表示される', js: true do
      visit admin_inquiry_path(inquiry)

      # メッセージ履歴セクション内のカードを取得
      message_section = page.find('h2', text: 'メッセージ履歴').find(:xpath, '..')
      message_cards = message_section.all('.card .whitespace-pre-wrap')

      # 古い順に表示されることを確認
      expect(message_cards[0].text).to include('最初のメッセージ')
      expect(message_cards[1].text).to include('2番目のメッセージ')
      expect(message_cards[2].text).to include('3番目のメッセージ')
    end
  end

  describe '認可チェック' do
    before do
      sign_out admin_user
      sign_in normal_user
    end

    let!(:inquiry) { create(:inquiry, user: normal_user) }

    it '一般ユーザーは管理者ページにアクセスできない', js: true do
      visit admin_inquiries_path

      expect(page).to have_current_path(user_root_path)
      expect(page).to have_content('管理者権限が必要です')
    end

    it '一般ユーザーは管理者詳細ページにアクセスできない', js: true do
      visit admin_inquiry_path(inquiry)

      expect(page).to have_current_path(user_root_path)
      expect(page).to have_content('管理者権限が必要です')
    end
  end

  describe 'ナビゲーション確認' do
    it 'ヘッダーに管理者お問い合わせリンクが表示される', js: true do
      visit admin_root_path

      # デスクトップナビゲーション
      within('nav.hidden.md\\:flex') do
        expect(page).to have_link('お問い合わせ', href: admin_inquiries_path)
      end
    end
  end
end
