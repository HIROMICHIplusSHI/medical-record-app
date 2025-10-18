class ConsentFormTemplate < ApplicationRecord
  # アソシエーション
  belongs_to :user
  has_many :consent_form_items, -> { order(:position) }, dependent: :destroy, inverse_of: :consent_form_template
  has_many :patient_consents, dependent: :restrict_with_error

  # ネストフォーム
  accepts_nested_attributes_for :consent_form_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  # バリデーション
  validates :title, presence: true
  validates :title, uniqueness: { scope: :user_id, message: 'はすでに存在します' }

  # スコープ
  scope :active, -> { where(is_active: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description id is_active title updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consent_form_items patient_consents user]
  end
end
