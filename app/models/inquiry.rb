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

  after_save :clear_unread_count_cache, if: :saved_change_to_status?

  def status_i18n
    I18n.t("activerecord.attributes.inquiry.statuses.#{status}")
  end

  private

  # ステータス変更時に未読件数キャッシュをクリア
  def clear_unread_count_cache
    Rails.cache.delete('admin_unread_inquiry_count')
  end
end
