class Tag < ApplicationRecord
  belongs_to :user
  has_many :medical_record_tags, dependent: :destroy
  has_many :medical_records, through: :medical_record_tags

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { scope: :user_id }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'はHex形式で入力してください' }, allow_blank: true

  scope :by_name, -> { order(:name) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  # Ransack設定
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name category color created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user medical_records]
  end
end
