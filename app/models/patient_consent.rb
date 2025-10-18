class PatientConsent < ApplicationRecord
  # アソシエーション
  belongs_to :patient
  belongs_to :consent_form_template
  belongs_to :medical_record
  belongs_to :facility_doctor
  belongs_to :user

  has_many :consent_item_responses, dependent: :destroy
  has_one_attached :signature_image

  # ネストフォーム
  accepts_nested_attributes_for :consent_item_responses,
                                allow_destroy: true

  # 暗号化（個人情報保護）
  encrypts :signature_data
  encrypts :practitioner_name
  encrypts :facility_name
  encrypts :facility_address
  encrypts :facility_phone

  # バリデーション
  validates :patient, :consent_form_template, :medical_record,
            :facility_doctor, :user, presence: true
  validates :agreed_at, presence: true
  validates :signature_data, presence: { message: '署名が必要です' }

  # カスタムバリデーション：必須項目のチェック確認
  validate :all_required_items_checked, on: :create

  # コールバック
  before_create :snapshot_facility_info

  # スコープ
  scope :recent, -> { order(agreed_at: :desc) }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :for_medical_record, ->(record_id) { where(medical_record_id: record_id) }

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[agreed_at created_at id medical_record_id patient_id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consent_form_template consent_item_responses facility_doctor medical_record patient user]
  end

  private

  # 施設情報のスナップショット保存
  def snapshot_facility_info
    facility = medical_record.facility
    self.facility_name = facility.name
    self.facility_address = facility.address
    self.facility_phone = facility.phone
    self.practitioner_name = user.company_name || user.email
  end

  # 必須項目がすべてチェックされているか確認
  def all_required_items_checked
    return if consent_form_template.blank?

    required_items = consent_form_template.consent_form_items.where(is_required: true)
    checked_item_ids = consent_item_responses.select(&:checked).map(&:consent_form_item_id)

    required_items.each do |item|
      errors.add(:base, "必須項目「#{item.content}」にチェックが必要です") unless checked_item_ids.include?(item.id)
    end
  end
end
