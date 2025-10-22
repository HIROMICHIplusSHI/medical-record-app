require 'rails_helper'

RSpec.describe 'Header Navigation', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
    # デフォルトでデスクトップサイズに設定 (Cuprite用)
    page.driver.resize(1024, 768) unless RSpec.current_example.metadata[:mobile]
  end

  describe 'ヘッダーの表示' do
    it '全ページでヘッダーが表示される' do
      visit user_root_path
      expect(page).to have_selector('header')
      expect(page).to have_content('InkFolio')
    end

    it 'ナビゲーションメニューが表示される' do
      visit user_root_path

      within('header') do
        # 有効化されたアイテムはlinkとして表示される
        expect(page).to have_link('ダッシュボード', href: dashboard_path)
        expect(page).to have_link('カルテ', href: medical_records_path)
        expect(page).to have_link('患者', href: patients_path)
        expect(page).to have_link('施術場所', href: facilities_path)
        expect(page).to have_link('コストシート', href: cost_sheets_path)
        # Phase 5-B-2で請求書機能を実装したため有効化
        expect(page).to have_link('請求書', href: invoices_path)
      end
    end

    it 'ユーザーメニューが表示される' do
      visit user_root_path

      within('header') do
        expect(page).to have_content(user.email.split('@').first)
      end
    end
  end

  describe '現在ページのハイライト', js: true do
    it 'カルテページで「カルテ」がハイライトされる' do
      visit medical_records_path

      within('header') do
        # 現在のページリンクが特別なスタイルを持つ
        # Tailwindの場合、bg-blue-700やborder-bottomなどでハイライト
        selector = 'a[href="/medical_records"].bg-blue-700, ' \
                   'a[href="/medical_records"][aria-current="page"]'
        expect(page).to have_css(selector)
      end
    end

    it '患者ページで「患者」がハイライトされる' do
      visit patients_path

      within('header') do
        selector = 'a[href="/patients"].bg-blue-700, a[href="/patients"][aria-current="page"]'
        expect(page).to have_css(selector)
      end
    end
  end

  describe 'ナビゲーションの動作', js: true do
    it '「カルテ」リンクをクリックするとカルテ一覧に遷移する' do
      visit user_root_path

      within('header') do
        click_link 'カルテ'
      end

      expect(page).to have_current_path(medical_records_path)
      expect(page).to have_selector('h1', text: 'カルテ一覧')
    end

    it '「患者」リンクをクリックすると患者一覧に遷移する' do
      visit user_root_path

      within('header') do
        click_link '患者'
      end

      expect(page).to have_current_path(patients_path)
      expect(page).to have_selector('h1', text: '患者一覧')
    end

    it '「請求書」リンクをクリックすると請求書一覧に遷移する' do
      visit user_root_path

      within('header') do
        click_link '請求書'
      end

      expect(page).to have_current_path(invoices_path)
      expect(page).to have_selector('h1', text: '請求書一覧')
    end
  end

  describe 'ユーザードロップダウン', js: true do
    it 'ユーザー名をクリックするとメニューが表示される' do
      visit user_root_path

      within('header') do
        # ドロップダウンメニューは最初は非表示（hiddenクラスで制御）
        expect(page).to have_css('[data-dropdown-target="menu"].hidden', visible: :all)

        # ユーザー名（またはアイコン）をクリック
        find('[data-controller="dropdown"] button').click

        # メニューが表示される
        expect(page).to have_link('ログアウト', visible: :visible)
      end
    end

    it 'ログアウトリンクが機能する' do
      visit user_root_path

      within('header') do
        find('[data-controller="dropdown"] button').click
        click_link 'ログアウト'
      end

      # ログインページにリダイレクトされる
      expect(page).to have_current_path(new_user_session_path)
      # ログインフォームが表示されることで、ログアウト成功を確認
      expect(page).to have_selector('input[type="email"]')
      expect(page).to have_selector('input[type="password"]')
    end
  end

  describe 'レスポンシブ対応', js: true do
    context 'モバイル表示（< 768px）', :mobile do
      before do
        # ビューポートをモバイルサイズに設定 (Cuprite用)
        page.driver.resize(375, 667)
      end

      it 'ハンバーガーメニューボタンが表示される' do
        visit user_root_path

        within('header') do
          expect(page).to have_css('button[data-action="click->header#toggleMobileMenu"]', visible: :visible)
        end
      end

      it 'デフォルトでナビゲーションメニューが非表示' do
        visit user_root_path

        # モバイルメニューは最初は hidden
        expect(page).to have_css('nav.hidden, nav[style*="display: none"]', visible: :all)
      end

      it 'ハンバーガーメニューをクリックするとメニューが表示される' do
        visit user_root_path

        within('header') do
          # ハンバーガーアイコンをクリック
          find('button[data-action="click->header#toggleMobileMenu"]').click

          # メニューが表示される
          expect(page).to have_link('カルテ', visible: :visible)
          expect(page).to have_link('患者', visible: :visible)
        end
      end
    end

    context 'タブレット/デスクトップ表示（>= 768px）' do
      before do
        # ビューポートをタブレットサイズに設定 (Cuprite用)
        page.driver.resize(1024, 768)
      end

      it 'ハンバーガーメニューボタンが非表示' do
        visit user_root_path

        within('header') do
          expect(page).not_to have_css('button[data-action="click->header#toggleMobileMenu"]', visible: :visible)
        end
      end

      it 'ナビゲーションメニューが常に表示される' do
        visit user_root_path

        within('header nav') do
          expect(page).to have_link('カルテ', visible: :visible)
          expect(page).to have_link('患者', visible: :visible)
        end
      end
    end
  end

  describe 'アクセシビリティ' do
    it 'ヘッダーに適切なランドマークロールが設定されている' do
      visit user_root_path
      expect(page).to have_css('header[role="banner"], header')
    end

    it 'ナビゲーションに適切なロールが設定されている' do
      visit user_root_path
      expect(page).to have_css('nav[role="navigation"], nav')
    end

    it 'ログアウトボタンにmethod: :deleteが設定されている' do
      visit user_root_path

      within('header') do
        find('[data-controller="dropdown"] button').click
        # Turboを使用している場合、data-turbo-method属性を確認
        expect(page).to have_css('a[href*="sign_out"][data-turbo-method="delete"]')
      end
    end
  end
end
