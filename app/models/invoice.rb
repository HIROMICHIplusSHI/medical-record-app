class Invoice < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :facility
  has_many :invoice_items, dependent: :destroy

  # Enums
  enum :status, { draft: 0, issued: 1, sent: 2, paid: 3, cancelled: 4 }, validate: true

  # Callbacks
  before_validation :generate_invoice_number, if: -> { invoice_number.blank? }

  # Validations
  validates :invoice_number, presence: true, uniqueness: true
  validates :issued_at, presence: true
  validates :billing_period_start, presence: true
  validates :billing_period_end, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :billing_period_end_after_start

  # Scopes
  scope :recent, -> { order(issued_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  # 指定期間と重複する請求書を取得
  scope :by_period, lambda { |start_date, end_date|
    where('billing_period_start <= ? AND billing_period_end >= ?', end_date, start_date)
  }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[invoice_number status issued_at billing_period_start billing_period_end total_amount created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user facility invoice_items]
  end

  # Instance Methods

  # 請求書明細の合計金額を計算
  def calculate_total_amount
    invoice_items.sum(:amount)
  end

  # 合計金額を再計算して保存
  def update_total_amount!
    update!(total_amount: calculate_total_amount)
  end

  # 請求期間を文字列で返す
  def period
    "#{billing_period_start} ~ #{billing_period_end}"
  end

  # 編集可能かどうか
  def can_edit?
    draft? || issued?
  end

  # 削除可能かどうか
  def can_delete?
    draft?
  end

  private

  # 請求書番号の自動生成
  # 並行処理対策として悲観的ロック（FOR UPDATE）を使用
  def generate_invoice_number
    date_prefix = Date.current.strftime('%Y%m')

    Invoice.transaction do
      last_invoice = Invoice.where('invoice_number LIKE ?', "INV-#{date_prefix}-%")
                            .lock('FOR UPDATE')
                            .order(invoice_number: :desc)
                            .first

      if last_invoice && last_invoice.invoice_number =~ /INV-#{date_prefix}-(\d{4})/
        last_number = ::Regexp.last_match(1).to_i
        new_number = last_number + 1
      else
        new_number = 1
      end

      self.invoice_number = "INV-#{date_prefix}-#{new_number.to_s.rjust(4, '0')}"
    end
  end

  # 請求期間の妥当性検証
  def billing_period_end_after_start
    return if billing_period_end.blank? || billing_period_start.blank?

    return unless billing_period_end < billing_period_start

    errors.add(:billing_period_end, 'は請求期間開始日以降の日付を指定してください')
  end
end
