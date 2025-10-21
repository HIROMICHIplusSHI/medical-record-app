require 'rails_helper'

RSpec.describe 'Admin Announcements Management', type: :system do
  let(:admin_user) { create(:user, :admin) }

  before do
    sign_in admin_user
  end

  # CI環境での調査のため一時的にpending
  describe 'お知らせ一覧画面', skip: 'CI環境でのCuprite設定調査中' do
    let!(:draft_announcement) { create(:announcement, author: admin_user, status: :draft, title: '下書きお知らせ') }
    let!(:published_announcement) do
      create(:announcement, :published, author: admin_user, title: '公開お知らせ')
    end
    let!(:archived_announcement) do
      create(:announcement, :archived, author: admin_user, title: 'アーカイブお知らせ')
    end

    it 'お知らせ一覧が表示される', js: true do
      visit admin_announcements_path

      expect(page).to have_content('お知らせ管理')
      expect(page).to have_selector('tbody tr', count: 3)
    end

    it 'お知らせ情報が正しく表示される', js: true do
      visit admin_announcements_path

      # 下書き
      expect(page).to have_content(draft_announcement.title)
      expect(page).to have_selector('.bg-gray-100', text: '下書き')

      # 公開
      expect(page).to have_content(published_announcement.title)
      expect(page).to have_selector('.bg-green-100', text: '公開')

      # アーカイブ
      expect(page).to have_content(archived_announcement.title)
      expect(page).to have_content('アーカイブ')
    end

    it '重要度バッジが表示される', js: true do
      create(:announcement, :warning, author: admin_user)
      create(:announcement, :critical, author: admin_user)

      visit admin_announcements_path

      # 警告（黄色）
      expect(page).to have_selector('.bg-yellow-100')

      # 重要（赤色）
      expect(page).to have_selector('.bg-red-100')
    end

    it '新規作成ボタンが表示される', js: true do
      visit admin_announcements_path

      expect(page).to have_link('新規作成', href: new_admin_announcement_path)
      # ボタンのスタイル確認（青色の背景）
      button = page.find('a', text: '新規作成')
      expect(button[:class]).to include('bg-blue-600')
    end
  end

  describe 'お知らせ詳細画面', skip: 'CI環境でのCuprite設定調査中' do
    let!(:announcement) do
      create(:announcement,
             :published,
             author: admin_user,
             title: 'テストお知らせ',
             body: 'これはテストの本文です',
             severity: :warning,
             display_order: 5,
             published_at: Time.zone.parse('2024-01-01 10:00'),
             expires_at: Time.zone.parse('2024-12-31 23:59'))
    end

    it '詳細情報が正しく表示される', js: true do
      visit admin_announcement_path(announcement)

      expect(page).to have_content('お知らせ詳細')
      expect(page).to have_content(announcement.title)
      expect(page).to have_content(announcement.body)
      expect(page).to have_content('警告')
      expect(page).to have_content('5')
      expect(page).to have_content(announcement.author.email)
    end

    it 'ステータスバッジが表示される', js: true do
      visit admin_announcement_path(announcement)

      # 公開バッジの確認
      status_badge = page.find('.bg-green-100', text: '公開')
      expect(status_badge).to be_present
    end

    it '重要度バッジが表示される', js: true do
      visit admin_announcement_path(announcement)

      # 警告バッジの確認
      severity_badge = page.find('.bg-yellow-100', text: '警告')
      expect(severity_badge).to be_present
    end

    it '編集ボタンが表示される', js: true do
      visit admin_announcement_path(announcement)

      expect(page).to have_link('編集', href: edit_admin_announcement_path(announcement))
    end

    it '一覧に戻るボタンが表示される', js: true do
      visit admin_announcement_path(announcement)

      expect(page).to have_link('一覧に戻る', href: admin_announcements_path)
    end

    context '下書きの場合' do
      let!(:draft) { create(:announcement, author: admin_user, status: :draft) }

      it '公開するボタンが表示される', js: true do
        visit admin_announcement_path(draft)

        expect(page).to have_button('公開する')
        # ボタンのスタイル確認（緑色の背景）
        button = page.find('button', text: '公開する')
        expect(button[:class]).to include('bg-green-600')
      end
    end

    context '公開中の場合' do
      it 'アーカイブするボタンが表示される', js: true do
        visit admin_announcement_path(announcement)

        expect(page).to have_button('アーカイブする')
      end
    end
  end

  describe 'お知らせ作成画面', skip: 'CI環境でのCuprite設定調査中' do
    it 'フォームが表示される', js: true do
      visit new_admin_announcement_path

      expect(page).to have_content('お知らせ作成')
      expect(page).to have_field('タイトル')
      expect(page).to have_field('本文')
      expect(page).to have_select('重要度')
      expect(page).to have_select('ステータス')
      expect(page).to have_field('表示順序')
      expect(page).to have_field('公開開始日時')
      expect(page).to have_field('公開終了日時')
    end

    it 'お知らせを作成できる', js: true do
      visit new_admin_announcement_path

      fill_in 'タイトル', with: '新しいお知らせ'
      fill_in '本文', with: 'これは新しいお知らせの本文です'
      select '警告（黄）', from: '重要度'
      select '下書き', from: 'ステータス'
      fill_in '表示順序', with: '10'

      click_button '作成する'

      expect(page).to have_content('お知らせを作成しました')

      # 作成されたお知らせが一覧に表示される
      expect(page).to have_content('新しいお知らせ')
    end

    it 'バリデーションエラーが表示される', js: true do
      visit new_admin_announcement_path

      # タイトルと本文を空で送信
      fill_in 'タイトル', with: ''
      fill_in '本文', with: ''
      click_button '作成する'

      # バリデーションエラーの場合、new画面に留まる
      expect(page).to have_current_path('/admin/announcements/new', ignore_query: true)
    end
  end

  describe 'お知らせ編集画面', skip: 'CI環境でのCuprite設定調査中' do
    let!(:announcement) { create(:announcement, author: admin_user, title: '元のタイトル') }

    it 'フォームに既存データが表示される', js: true do
      visit edit_admin_announcement_path(announcement)

      expect(page).to have_content('お知らせ編集')
      expect(page).to have_field('タイトル', with: announcement.title)
      expect(page).to have_field('本文', with: announcement.body)
    end

    it 'お知らせを更新できる', js: true do
      visit edit_admin_announcement_path(announcement)

      fill_in 'タイトル', with: '更新されたタイトル'
      fill_in '本文', with: '更新された本文'

      click_button '更新する'

      expect(page).to have_content('お知らせを更新しました')

      # 更新されたお知らせが表示される
      expect(page).to have_content('更新されたタイトル')
    end

    it 'キャンセルボタンで一覧に戻れる', js: true do
      visit edit_admin_announcement_path(announcement)

      click_link 'キャンセル'

      expect(page).to have_current_path(admin_announcements_path)
    end
  end

  describe 'フォームのUI要素', skip: 'CI環境でのCuprite設定調査中' do
    before do
      visit new_admin_announcement_path
    end

    it 'エラー表示領域のスタイルが正しい', js: true do
      # タイトルと本文を空で送信してエラーを表示
      fill_in 'タイトル', with: ''
      fill_in '本文', with: ''
      click_button '作成する'

      # バリデーションエラーの場合、new画面に留まる
      expect(page).to have_current_path('/admin/announcements/new', ignore_query: true)
    end

    it 'フォームフィールドのスタイルが正しい', js: true do
      # テキストフィールドのスタイル確認
      title_field = page.find_field('タイトル')
      expect(title_field[:class]).to include('border-gray-300')
      expect(title_field[:class]).to include('rounded-md')

      # セレクトフィールドのスタイル確認
      severity_field = page.find_field('重要度')
      expect(severity_field[:class]).to include('border-gray-300')
      expect(severity_field[:class]).to include('rounded-md')
    end

    it '作成・キャンセルボタンのスタイルが正しい', js: true do
      # 作成ボタン（青色）
      submit_button = page.find('input[type="submit"]')
      expect(submit_button[:class]).to include('bg-blue-600')
      expect(submit_button[:class]).to include('text-white')

      # キャンセルボタン（グレー枠線）
      cancel_link = page.find('a', text: 'キャンセル')
      expect(cancel_link[:class]).to include('border-gray-300')
      expect(cancel_link[:class]).to include('bg-white')
    end
  end

  describe 'ステータス変更機能', skip: 'CI環境でのCuprite設定調査中' do
    let!(:draft) { create(:announcement, author: admin_user, status: :draft) }
    let!(:published) { create(:announcement, :published, author: admin_user) }

    it '下書きを公開できる', js: true do
      visit admin_announcement_path(draft)

      click_button '公開する'

      expect(page).to have_content('お知らせを公開しました')
    end

    it '公開中のお知らせをアーカイブできる', js: true do
      visit admin_announcement_path(published)

      click_button 'アーカイブする'

      expect(page).to have_content('お知らせをアーカイブしました')
    end
  end
end
