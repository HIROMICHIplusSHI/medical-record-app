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

  enum :category, {
    general: 0,
    bug_report: 1,
    feature_request: 2,
    other: 3,
  }

  enum :last_message_by, {
    user: 0,
    admin: 1,
  }

  scope :recent, -> { order(updated_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  after_create :clear_unread_count_cache
  after_save :clear_unread_count_cache, if: :saved_change_to_read_status?
  after_destroy :clear_unread_count_cache

  def status_i18n
    I18n.t("activerecord.attributes.inquiry.statuses.#{status}")
  end

  def category_i18n
    I18n.t("activerecord.attributes.inquiry.categories.#{category}")
  end

  private

  # ステータスまたは既読状態が変更されたかチェック
  def saved_change_to_read_status?
    saved_change_to_status? ||
      saved_change_to_last_message_by? ||
      saved_change_to_admin_read_at? ||
      saved_change_to_user_read_at?
  end

  # お問い合わせの作成・更新・削除時に未読件数キャッシュをクリア
  def clear_unread_count_cache
    # 管理者のキャッシュをクリア（pluckでメモリ効率化）
    admin_ids = User.where(role: :admin).pluck(:id)
    admin_ids.each do |admin_id|
      Rails.cache.delete("unread_inquiry_count_user_#{admin_id}")
    end

    # お問い合わせ作成者（ユーザー）のキャッシュをクリア
    Rails.cache.delete("unread_inquiry_count_user_#{user_id}") if user_id.present?
  end
end
