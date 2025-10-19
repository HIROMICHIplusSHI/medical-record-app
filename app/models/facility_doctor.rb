class FacilityDoctor < ApplicationRecord
  # アソシエーション
  belongs_to :facility
  has_many :patient_consents, dependent: :restrict_with_error

  # 暗号化（要配慮個人情報のため）
  encrypts :medical_license_number, deterministic: true

  # バリデーション
  validates :name, presence: true
  validates :medical_license_number,
            uniqueness: { scope: :facility_id, message: 'はすでに存在します' },
            allow_blank: true

  # 表示用メソッド
  def display_name
    medical_license_number.present? ? "#{name} (#{medical_license_number})" : name
  end

  alias name_with_license display_name

  # ライセンス番号のみを取得（表示用）
  def license_number
    medical_license_number.present? ? medical_license_number : '未登録'
  end
end
