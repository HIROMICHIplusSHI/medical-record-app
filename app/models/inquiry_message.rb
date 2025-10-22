class InquiryMessage < ApplicationRecord
  belongs_to :inquiry, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(created_at: :asc) }

  after_create :update_inquiry_last_message_by

  private

  # メッセージ作成時にお問い合わせの最終返信者を更新
  def update_inquiry_last_message_by
    inquiry.update(last_message_by: user.admin? ? :admin : :user)
  end
end
