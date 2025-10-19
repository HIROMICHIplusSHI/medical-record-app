class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice, only: %i[show edit update destroy generate_pdf download_pdf preview_pdf refresh_items]
  skip_before_action :verify_authenticity_token, only: [:preview_pdf]

  def index
    @q = current_user.invoices.ransack(params[:q])
    @invoices = @q.result
                  .includes(:facility)
                  .recent
                  .page(params[:page])
                  .per(20)
  end

  def show
    @invoice_items = @invoice.invoice_items
                             .includes(medical_record: :patient)
                             .order('medical_records.visit_date ASC')
  end

  def new
    @invoice = Invoice.new
    @facilities = Facility.order(:name)
  end

  def create
    @invoice = build_new_invoice
    if save_invoice_with_items
      redirect_to @invoice, notice: '請求書を作成しました。'
    else
      @facilities = Facility.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @facilities = Facility.order(:name)
  end

  def update
    if @invoice.update(invoice_params.except(:facility_id))
      redirect_to @invoice, notice: '請求書を更新しました。'
    else
      @facilities = Facility.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: '請求書を削除しました。'
  end

  def generate_pdf
    # 請求明細がない場合はエラー
    if @invoice.invoice_items.empty?
      redirect_to @invoice, alert: '請求明細がないためPDFを生成できません。'
      return
    end

    # 税表示フラグを更新
    @invoice.update(tax_display: params[:tax_display] == '1')

    # PDF生成サービスを呼び出し
    InvoicePdfGenerator.new(@invoice).generate
    redirect_to @invoice, notice: 'PDFを生成しました。'
  rescue StandardError => e
    Rails.logger.error "PDF Generation Error: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    redirect_to @invoice, alert: "PDF生成中にエラーが発生しました: #{e.message}"
  end

  def download_pdf
    pdf_path = Rails.root.join('tmp', 'pdfs', "invoice_#{@invoice.id}.pdf")

    # PDFファイルが存在しない場合はエラー
    unless File.exist?(pdf_path)
      redirect_to @invoice, alert: 'PDFが生成されていません。先にPDF生成を実行してください。'
      return
    end

    # PDFファイルを送信
    send_file pdf_path,
              type: 'application/pdf',
              disposition: 'attachment',
              filename: sanitize_filename("invoice_#{@invoice.invoice_number}.pdf")
  end

  def preview_pdf
    Rails.logger.info "PDF Preview: Started for invoice #{params[:id]} with tax_display=#{params[:tax_display]}"

    # 請求明細がない場合はエラー
    if @invoice.invoice_items.empty?
      Rails.logger.warn 'PDF Preview: No invoice items found'
      render plain: '請求明細がないためPDFをプレビューできません。', status: :unprocessable_entity
      return
    end

    # 一時的に税表示フラグを設定（DBには保存しない）
    @invoice.tax_display = params[:tax_display] == 'true'
    Rails.logger.info "PDF Preview: tax_display set to #{@invoice.tax_display}"

    # PDF生成（一時ファイル）
    begin
      generator = InvoicePdfGenerator.new(@invoice)
      pdf_content = generator.generate_to_string
      Rails.logger.info "PDF Preview: PDF content generated, size: #{pdf_content.bytesize} bytes"

      send_data pdf_content,
                type: 'application/pdf',
                disposition: 'inline',
                filename: sanitize_filename("preview_invoice_#{@invoice.invoice_number}.pdf")

      Rails.logger.info 'PDF Preview: Successfully sent PDF'
    rescue StandardError => e
      Rails.logger.error "PDF Preview Error: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render plain: "PDF生成中にエラーが発生しました: #{e.message}", status: :internal_server_error
    end
  end

  def refresh_items
    unless @invoice.can_refresh_items?
      redirect_to @invoice, alert: 'ドラフト状態の請求書のみ明細を更新できます。'
      return
    end

    ActiveRecord::Base.transaction do
      # 既存の明細を削除
      @invoice.invoice_items.destroy_all

      # 期間内のカルテから明細を再作成
      medical_records_count = create_invoice_items_from_medical_records

      # カルテが0件の場合はロールバックしてエラー表示
      raise ActiveRecord::Rollback, '該当期間にカルテが見つかりません。' if medical_records_count.zero?
    end

    redirect_to @invoice, notice: '請求明細を更新しました。'
  rescue ActiveRecord::Rollback => e
    redirect_to @invoice, alert: e.message
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end

  def build_new_invoice
    invoice = Invoice.new(invoice_params)
    invoice.user = current_user
    invoice.issued_at = Time.current
    invoice.status = :draft
    invoice
  end

  def save_invoice_with_items
    ActiveRecord::Base.transaction do
      return false unless @invoice.save

      medical_records_count = create_invoice_items_from_medical_records
      raise ActiveRecord::Rollback, '該当期間にカルテが見つかりません。' if medical_records_count.zero?

      true
    end
  rescue ActiveRecord::Rollback => e
    @invoice.errors.add(:base, e.message)
    false
  end

  def invoice_params
    params.require(:invoice).permit(
      :facility_id,
      :billing_period_start,
      :billing_period_end,
      :status,
      :notes
    )
  end

  # 該当期間・施設のカルテから請求明細を自動作成
  # @return [Integer] 作成した明細の件数
  def create_invoice_items_from_medical_records
    medical_records = MedicalRecord
                      .where(user: current_user)
                      .where(facility_id: @invoice.facility_id)
                      .where(visit_date: @invoice.billing_period_start..@invoice.billing_period_end)
                      .includes(:cost_items)

    medical_records.each do |record|
      description = build_invoice_item_description(record)
      @invoice.invoice_items.create!(
        medical_record: record,
        description: description,
        amount: record.total_cost
      )
    end

    medical_records.size
  end

  # 請求明細の内容を生成（コスト項目内訳のみ）
  def build_invoice_item_description(record)
    return '明細なし' unless record.cost_items.any?

    record.cost_items.map do |item|
      formatted_price = item.total_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
      "#{item.item_name} x #{item.quantity}: ¥#{formatted_price}"
    end.join("\n")
  end

  # ファイル名をサニタイズ（パストラバーサル対策）
  def sanitize_filename(filename)
    # 英数字、ハイフン、アンダースコア、ドット以外を除去
    filename.gsub(%r{[^\w\-.]}, '_')
  end
end
