class FacilityDoctor < ApplicationRecord
  # アソシエーション
  belongs_to :facility
  has_many :patient_consents, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true
  validates :medical_license_number,
            uniqueness: { scope: :facility_id, message: 'はすでに存在します' },
            allow_blank: true

  # 表示用メソッド
  def display_name
    medical_license_number.present? ? "#{name} (#{medical_license_number})" : name
  end
end
