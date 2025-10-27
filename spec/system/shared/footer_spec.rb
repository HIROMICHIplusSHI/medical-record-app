require 'rails_helper'

RSpec.describe 'Footer', type: :system do
  describe 'フッター表示条件', js: true do
    context '認証済みユーザー' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'ダッシュボードでフッターが表示される' do
        visit user_dashboard_path

        expect(page).to have_selector('footer')
        expect(page).to have_link('利用規約', href: terms_path)
        expect(page).to have_link('プライバシーポリシー', href: privacy_path)
        expect(page).to have_link('お問い合わせ', href: inquiries_path)
      end
    end

    context '未認証ユーザー' do
      it 'ウェルカムページではフッターが表示されない' do
        visit root_path

        expect(page).not_to have_selector('footer')
      end

      it '利用規約ページでフッターが表示される' do
        visit terms_path

        expect(page).to have_selector('footer')
        expect(page).to have_link('利用規約', href: terms_path)
        expect(page).to have_link('プライバシーポリシー', href: privacy_path)
        expect(page).not_to have_link('お問い合わせ')
      end

      it 'プライバシーポリシーページでフッターが表示される' do
        visit privacy_path

        expect(page).to have_selector('footer')
        expect(page).to have_link('利用規約', href: terms_path)
        expect(page).to have_link('プライバシーポリシー', href: privacy_path)
        expect(page).not_to have_link('お問い合わせ')
      end
    end
  end

  describe 'フッターリンク遷移', js: true do
    let(:user) { create(:user) }

    before { sign_in user }

    it 'フッターから利用規約へアクセスできる' do
      visit user_dashboard_path

      within('footer') do
        click_link '利用規約'
      end

      expect(page).to have_current_path(terms_path)
      expect(page).to have_selector('h1', text: '電子カルテシステム利用規約')
    end

    it 'フッターからプライバシーポリシーへアクセスできる' do
      visit user_dashboard_path

      within('footer') do
        click_link 'プライバシーポリシー'
      end

      expect(page).to have_current_path(privacy_path)
      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
    end

    it '利用規約ページから他ページへ遷移できる' do
      visit terms_path

      within('footer') do
        click_link 'プライバシーポリシー'
      end

      expect(page).to have_current_path(privacy_path)
      expect(page).to have_selector('h1', text: 'プライバシーポリシー')
    end
  end
end
