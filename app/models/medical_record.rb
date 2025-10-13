class MedicalRecord < ApplicationRecord
  belongs_to :patient
  belongs_to :facility
  belongs_to :user
  has_many :cost_items, dependent: :destroy
  has_many_attached :photos

  accepts_nested_attributes_for :cost_items, allow_destroy: true, reject_if: :all_blank

  # コスト項目の合計金額を計算
  def total_cost
    cost_items.sum(:total_price)
  end

  # バリデーション
  validates :visit_date, presence: true
  validates :treatment_location, presence: true, length: { maximum: 200 }
  validates :chief_complaint, presence: true
  validates :diagnosis, presence: true
  validates :treatment_content, presence: true
  validate :photos_count_limit
  validate :photos_size_limit

  # スコープ
  scope :recent, -> { order(visit_date: :desc, created_at: :desc) }
  scope :by_date_range, lambda { |start_date, end_date|
    where(visit_date: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) if patient_id.present? }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) if facility_id.present? }

  private

  def photos_count_limit
    return unless photos.attached?

    return unless photos.count > 5

    errors.add(:photos, 'は最大5枚までアップロードできます')
  end

  def photos_size_limit
    return unless photos.attached?

    photos.each do |photo|
      errors.add(:photos, "#{photo.filename}のサイズが10MBを超えています") if photo.byte_size > 10.megabytes
    end
  end
end
