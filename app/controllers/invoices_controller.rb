class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice, only: %i[show edit update destroy generate_pdf download_pdf refresh_items]

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
    # TODO: Phase 5-B-3で実装
    redirect_to @invoice, alert: 'PDF生成機能は Phase 5-B-3 で実装予定です。'
  end

  def download_pdf
    # TODO: Phase 5-B-3で実装
    redirect_to @invoice, alert: 'PDF生成機能は Phase 5-B-3 で実装予定です。'
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
end
