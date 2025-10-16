class Facility < ApplicationRecord
  belongs_to :user
  has_many :medical_records, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }

  # MedicalRecordモデル実装後に有効化
  # def has_records?
  #   medical_records.exists?
  # end

  # def total_revenue(start_date = nil, end_date = nil)
  #   records = medical_records
  #   records = records.where('treatment_date >= ?', start_date) if start_date
  #   records = records.where('treatment_date <= ?', end_date) if end_date
  #   records.sum(:total_amount)
  # end

  # def medical_records_count
  #   medical_records.count
  # end

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[address created_at email id name notes phone updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[invoices medical_records user]
  end
end
