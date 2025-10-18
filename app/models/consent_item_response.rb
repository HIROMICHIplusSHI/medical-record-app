class ConsentItemResponse < ApplicationRecord
  # アソシエーション
  belongs_to :patient_consent
  belongs_to :consent_form_item

  # バリデーション
  validates :patient_consent, :consent_form_item, presence: true
  validates :checked, inclusion: { in: [true, false] }
  validates :consent_form_item_id,
            uniqueness: { scope: :patient_consent_id,
                          message: '同じ項目への回答がすでに存在します', }

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[checked consent_form_item_id created_at id patient_consent_id updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consent_form_item patient_consent]
  end
end
