class Questionnaire < ApplicationRecord
  # アソシエーション
  belongs_to :patient

  # 基本情報の暗号化
  encrypts :full_name
  encrypts :full_name_kana
  encrypts :birth_date
  encrypts :gender
  encrypts :phone
  encrypts :email
  encrypts :postal_code
  encrypts :address
  encrypts :emergency_contact

  # 医療情報の暗号化（JSON形式）
  encrypts :medical_conditions
  encrypts :allergies
  encrypts :current_medications
  encrypts :past_surgeries
  encrypts :pregnancy_info

  # 施術情報の暗号化（JSON形式）
  encrypts :desired_treatments
  encrypts :past_treatments
  encrypts :skin_conditions
  encrypts :other_concerns

  # バリデーション
  validates :patient, uniqueness: { message: 'はすでに問診票が存在します' }
  # 基本情報：full_nameとphoneのみ必須（予約時の最小情報）
  # full_name_kana, birth_date, genderは任意（来院時に記入）
  validates :full_name, :phone, presence: true

  # コールバック
  before_save :set_nurse_confirmation, if: :nurse_confirmed_changed_to_true?

  private

  def nurse_confirmed_changed_to_true?
    nurse_confirmed? && nurse_confirmed_changed? && nurse_confirmed_was == false
  end

  def set_nurse_confirmation
    self.nurse_confirmed_at = Time.current
    self.nurse_name = patient.user.email if patient&.user
  end

  public

  # JSONフィールドのアクセサー
  # medical_conditions: { has_conditions: bool, conditions: [], other_condition: string }
  def medical_conditions_data
    medical_conditions.present? ? JSON.parse(medical_conditions) : {}
  rescue JSON::ParserError
    {}
  end

  def medical_conditions_data=(value)
    self.medical_conditions = value.to_json
  end

  # allergies: { has_allergies: bool, allergy_types: [], details: {} }
  def allergies_data
    allergies.present? ? JSON.parse(allergies) : {}
  rescue JSON::ParserError
    {}
  end

  def allergies_data=(value)
    self.allergies = value.to_json
  end

  # current_medications: { taking_medications: bool, medication_types: [], other_medication: string }
  def current_medications_data
    current_medications.present? ? JSON.parse(current_medications) : {}
  rescue JSON::ParserError
    {}
  end

  def current_medications_data=(value)
    self.current_medications = value.to_json
  end

  # past_surgeries: { has_surgeries: bool, details: string }
  def past_surgeries_data
    past_surgeries.present? ? JSON.parse(past_surgeries) : {}
  rescue JSON::ParserError
    {}
  end

  def past_surgeries_data=(value)
    self.past_surgeries = value.to_json
  end

  # pregnancy_info: { is_pregnant: bool, is_nursing: bool, might_be_pregnant: bool }
  def pregnancy_info_data
    pregnancy_info.present? ? JSON.parse(pregnancy_info) : {}
  rescue JSON::ParserError
    {}
  end

  def pregnancy_info_data=(value)
    self.pregnancy_info = value.to_json
  end

  # desired_treatments: { treatments: [], other_treatment: string }
  def desired_treatments_data
    desired_treatments.present? ? JSON.parse(desired_treatments) : {}
  rescue JSON::ParserError
    {}
  end

  def desired_treatments_data=(value)
    self.desired_treatments = value.to_json
  end

  # past_treatments: { has_experience: bool, details: {} }
  def past_treatments_data
    past_treatments.present? ? JSON.parse(past_treatments) : {}
  rescue JSON::ParserError
    {}
  end

  def past_treatments_data=(value)
    self.past_treatments = value.to_json
  end

  # skin_conditions: { conditions: [], other_condition: string }
  def skin_conditions_data
    skin_conditions.present? ? JSON.parse(skin_conditions) : {}
  rescue JSON::ParserError
    {}
  end

  def skin_conditions_data=(value)
    self.skin_conditions = value.to_json
  end
end
