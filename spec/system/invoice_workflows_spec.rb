require 'rails_helper'

RSpec.describe '請求書管理ワークフロー', type: :system do
  let(:user) { create(:user) }
  let!(:facility) { create(:facility, user: user, name: 'テスト施設') }
  let!(:patient) { create(:patient) }

  before do
    login_as user
  end

  describe '基本的な請求書管理フロー' do
    it 'ユーザーが請求書を作成・閲覧・更新・削除できる', js: true do
      # カルテを作成（請求書明細のため）
      create(:medical_record,
             user: user,
             facility: facility,
             patient: patient,
             visit_date: Date.current)

      # 請求書一覧にアクセス
      visit invoices_path
      expect(page).to have_content('請求書一覧')

      # 新規請求書作成
      click_link '新しい請求書を作成', match: :first
      expect(page).to have_current_path(new_invoice_path)

      # フォームに入力
      # Tom Select対応: 隠されているネイティブのselect要素に値を設定
      find('select#invoice_facility_id', visible: false).find('option', text: 'テスト施設', visible: false).select_option
      fill_in '請求期間開始日', with: Date.current.beginning_of_month
      fill_in '請求期間終了日', with: Date.current.end_of_month
      fill_in '備考', with: 'テスト請求書'

      click_button '作成'

      # 作成成功を確認
      expect(page).to have_content('請求書を作成しました')
      expect(page).to have_content('テスト施設')
      expect(page).to have_content('ドラフト')
      expect(page).to have_content('テスト請求書')

      # 一覧に戻って表示を確認
      visit invoices_path
      expect(page).to have_content('INV-')

      # 詳細画面へ
      click_link '表示', match: :first
      expect(page).to have_content('請求書詳細')
      expect(page).to have_content('テスト施設')

      # 編集
      click_link '編集'
      expect(page).to have_content('請求書を編集')

      # Tom Select対応
      find('select#invoice_status', visible: false).find('option', text: '発行済み', visible: false).select_option
      fill_in '備考', with: '更新済み請求書'

      click_button '更新'

      # 更新成功を確認
      expect(page).to have_content('請求書を更新しました')
      expect(page).to have_content('発行済み')
      expect(page).to have_content('更新済み請求書')
    end
  end

  describe '請求書検索機能' do
    let!(:invoice1) do
      create(:invoice,
             user: user,
             facility: facility,
             billing_period_start: '2025-01-01',
             billing_period_end: '2025-01-31',
             status: :draft)
    end

    let!(:invoice2) do
      create(:invoice,
             user: user,
             facility: facility,
             billing_period_start: '2025-02-01',
             billing_period_end: '2025-02-28',
             status: :issued)
    end

    # TODO: 検索ロジックの不具合修正が必要（Issue #21で対応）
    xit 'ステータスで検索できる', js: true do
      visit invoices_path

      # draft状態で検索
      # Tom Select対応
      find('select#q_status_eq', visible: false).find('option', text: 'ドラフト', visible: false).select_option
      click_button '検索'

      # Turbo Frame更新を待つ
      sleep 0.5

      # 検索結果の確認
      expect(page).to have_css('.bg-white.shadow-md.rounded-lg', count: 1)
      expect(page).to have_content(invoice1.invoice_number)
      expect(page).not_to have_content(invoice2.invoice_number)

      # クリア
      click_link 'クリア'
      sleep 0.5
      expect(page).to have_content(invoice1.invoice_number)
      expect(page).to have_content(invoice2.invoice_number)
    end

    # TODO: 検索ロジックの不具合修正が必要（Issue #21で対応）
    xit '請求書番号で検索できる', js: true do
      visit invoices_path

      fill_in '請求書番号', with: invoice1.invoice_number
      click_button '検索'

      # Turbo Frame更新を待つ
      sleep 0.5

      # 検索結果の確認
      expect(page).to have_content(invoice1.invoice_number)
      expect(page).not_to have_content(invoice2.invoice_number)
      expect(page).to have_css('.bg-white.shadow-md.rounded-lg', count: 1)
    end

    # TODO: 検索ロジックの不具合修正が必要（Issue #21で対応）
    xit '請求期間で検索できる', js: true do
      visit invoices_path

      fill_in 'q_billing_period_start_gteq', with: '2025-01-01'
      fill_in 'q_billing_period_end_lteq', with: '2025-01-31'
      click_button '検索'

      # Turbo Frame更新を待つ
      sleep 0.5

      # 検索結果の確認
      expect(page).to have_content(invoice1.invoice_number)
      expect(page).not_to have_content(invoice2.invoice_number)
      expect(page).to have_css('.bg-white.shadow-md.rounded-lg', count: 1)
    end
  end

  describe 'PDF機能' do
    let!(:medical_record) do
      create(:medical_record,
             user: user,
             facility: facility,
             patient: patient,
             visit_date: Date.current)
    end
    let!(:invoice) { create(:invoice, user: user, facility: facility) }
    let!(:invoice_item) { create(:invoice_item, invoice: invoice, medical_record: medical_record) }

    it 'PDF生成とダウンロードができる', js: true do
      visit invoice_path(invoice)

      # PDF生成ボタンをクリック
      click_button 'PDF生成'
      expect(page).to have_content('PDFを生成しました')

      # PDFダウンロードリンクをクリック（新しいタブで開く）
      # System testではダウンロードの実際の内容は確認せず、リンクの存在を確認
      expect(page).to have_link('PDFダウンロード')
    end

    it '請求明細がない場合はPDF生成できない', js: true do
      invoice_no_items = create(:invoice, user: user, facility: facility)
      visit invoice_path(invoice_no_items)

      click_button 'PDF生成'
      expect(page).to have_content('請求明細がないためPDFを生成できません')
    end
  end

  describe '権限による削除制御' do
    it 'draft状態の請求書のみ削除できる', js: true do
      draft_invoice = create(:invoice, user: user, facility: facility, status: :draft)
      issued_invoice = create(:invoice, user: user, facility: facility, status: :issued)

      # draft状態の請求書編集ページ
      visit edit_invoice_path(draft_invoice)
      expect(page).to have_button('請求書を削除')

      # issued状態の請求書編集ページ
      visit edit_invoice_path(issued_invoice)
      expect(page).not_to have_button('請求書を削除')
    end
  end

  describe 'ページネーション' do
    before do
      create_list(:invoice, 25, user: user, facility: facility)
    end

    it '20件ずつ表示される', js: true do
      visit invoices_path

      # 最初のページに20件表示（カードレイアウト）
      expect(page).to have_css('.bg-white.shadow-md.rounded-lg', count: 20)

      # ページネーションリンクが表示される
      expect(page).to have_css('.pagination')
    end
  end
end
