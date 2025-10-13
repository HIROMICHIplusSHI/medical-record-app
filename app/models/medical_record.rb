class MedicalRecord < ApplicationRecord
  belongs_to :patient
  belongs_to :facility
  belongs_to :user

  # バリデーション
  validates :visit_date, presence: true
  validates :treatment_location, presence: true, length: { maximum: 200 }
  validates :chief_complaint, presence: true
  validates :diagnosis, presence: true
  validates :treatment_content, presence: true

  # スコープ
  scope :recent, -> { order(visit_date: :desc, created_at: :desc) }
  scope :by_date_range, lambda { |start_date, end_date|
    where(visit_date: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) if patient_id.present? }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) if facility_id.present? }
end
