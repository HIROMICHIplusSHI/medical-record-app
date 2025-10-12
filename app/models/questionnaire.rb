class Questionnaire < ApplicationRecord
  # アソシエーション
  belongs_to :patient

  # 暗号化
  encrypts :medical_history
  encrypts :current_medications
  encrypts :allergies
  encrypts :past_surgeries
  encrypts :family_history
  encrypts :lifestyle_notes
  encrypts :concerns

  # バリデーション
  validates :patient, uniqueness: { message: 'はすでに存在します' }
end
