class Inquiry < ApplicationRecord
  belongs_to :user
  has_many :inquiry_messages, dependent: :destroy

  validates :subject, presence: true, length: { maximum: 100 }
  validates :status, presence: true

  enum :status, {
    open: 0,
    in_progress: 1,
    closed: 2,
  }

  scope :recent, -> { order(updated_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  def status_i18n
    I18n.t("activerecord.attributes.inquiry.statuses.#{status}")
  end
end
