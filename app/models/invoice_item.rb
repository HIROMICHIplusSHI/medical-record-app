class InvoiceItem < ApplicationRecord
  # Associations
  belongs_to :invoice
  belongs_to :medical_record

  # Validations
  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :medical_record_id, uniqueness: { scope: :invoice_id, message: 'はすでに存在します' }

  # Callbacks
  # トランザクション安全性のためafter_commitを使用
  after_commit :update_invoice_total, on: %i[create update]
  after_commit :update_invoice_total, on: :destroy

  # Instance Methods

  # カルテの基本情報を返す
  def medical_record_info
    "#{medical_record.patient.name} (#{medical_record.visit_date})"
  end

  private

  # 請求書の合計金額を更新
  def update_invoice_total
    invoice.update_total_amount!
  end
end
