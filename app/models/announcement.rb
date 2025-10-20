class Announcement < ApplicationRecord
  # Associations
  belongs_to :author, class_name: 'User'

  # Enums
  enum :status, {
    draft: 0,      # 下書き
    published: 1,  # 公開中
    archived: 2,   # アーカイブ
  }, default: :draft

  enum :severity, {
    info: 0,       # 情報（青）
    warning: 1,    # 警告（黄）
    critical: 2,   # 重要（赤）
  }, default: :info

  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 1000 }
  validates :published_at, presence: true, if: :published?
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, lambda {
    where(status: :published)
      .where('published_at <= ?', Time.current)
      .where('expires_at IS NULL OR expires_at > ?', Time.current)
      .order(display_order: :asc, published_at: :desc)
  }

  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def active?
    published? &&
      published_at.present? &&
      published_at <= Time.current &&
      (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
