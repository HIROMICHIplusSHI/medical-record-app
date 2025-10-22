class InquiryMessage < ApplicationRecord
  belongs_to :inquiry, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(created_at: :asc) }
end
