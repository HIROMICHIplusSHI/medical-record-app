class ConsentFormItem < ApplicationRecord
  # アソシエーション
  belongs_to :consent_form_template, inverse_of: :consent_form_items
  has_many :consent_item_responses, dependent: :destroy

  # バリデーション
  validates :content, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  # デフォルトスコープ
  default_scope { order(:position) }

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[consent_form_template_id content created_at id is_required position updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consent_form_template consent_item_responses]
  end
end
