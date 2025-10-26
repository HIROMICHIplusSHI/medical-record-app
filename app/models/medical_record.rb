require 'ostruct'

class MedicalRecord < ApplicationRecord
  belongs_to :patient
  belongs_to :facility
  belongs_to :user
  has_many :cost_items, dependent: :destroy
  has_many :medical_record_tags, dependent: :destroy
  has_many :tags, through: :medical_record_tags
  has_many :patient_consents, dependent: :restrict_with_error
  has_many_attached :photos

  accepts_nested_attributes_for :cost_items, allow_destroy: true, reject_if: :all_blank

  # コスト項目の合計金額を計算
  def total_cost
    cost_items.sum(:total_price)
  end

  # バリデーション
  validates :visit_date, presence: true
  validates :treatment_content, presence: true
  validate :photos_count_limit
  validate :photos_size_limit

  # コールバック
  after_validation :localize_cost_items_errors

  # スコープ
  scope :recent, -> { order(visit_date: :desc, created_at: :desc) }
  scope :by_date_range, lambda { |start_date, end_date|
    where(visit_date: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) if patient_id.present? }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) if facility_id.present? }

  # 売上集計用スコープ
  scope :in_period, ->(start_date, end_date) { where(visit_date: start_date..end_date) }
  scope :by_user, lambda { |user_id|
    joins(:facility).where(facilities: { user_id: user_id })
  }

  # Ransack設定
  def self.ransackable_attributes(_auth_object = nil)
    %w[visit_date treatment_content patient_id facility_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[patient facility patient_consents tags]
  end

  # 売上集計メソッド（請求割合を適用）
  def self.total_revenue(start_date, end_date)
    # 施設別売上を合計
    revenue_by_facility(start_date, end_date).sum(&:revenue)
  end

  def self.revenue_by_facility(start_date, end_date)
    in_period(start_date, end_date)
      .joins(:facility, :cost_items)
      .group('facilities.id', 'facilities.name', 'facilities.billing_rate')
      .select('facilities.id as facility_id,
               facilities.name as facility_name,
               facilities.billing_rate,
               SUM(cost_items.total_price) as cost_sum')
      .order('cost_sum DESC')
      .map { |result| build_facility_revenue(result) }
  end

  def self.monthly_revenue(year)
    (1..12).map do |month|
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      records_in_month = in_period(start_date, end_date).includes(:facility, :cost_items)

      # 各カルテの請求割合適用済み売上を計算
      revenue = records_in_month.sum do |record|
        total_cost = record.cost_items.sum(&:total_price)
        billing_rate = record.facility.billing_rate || 100.0
        total_cost * (billing_rate / 100.0)
      end

      {
        month: month,
        revenue: revenue,
        count: records_in_month.count,
      }
    end
  end

  # 施設別売上データの構築（請求割合を適用）
  def self.build_facility_revenue(result)
    billing_rate = result.billing_rate || 100.0
    actual_revenue = result.cost_sum * (billing_rate / 100.0)

    OpenStruct.new(
      id: result.facility_id,
      name: result.facility_name,
      billing_rate: billing_rate,
      revenue: actual_revenue
    )
  end

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

  def localize_cost_items_errors
    remove_cost_items_errors
    add_localized_cost_items_errors
  end

  def remove_cost_items_errors
    cost_items_error_keys = errors.attribute_names.select { |key| key.to_s.start_with?('cost_items') }
    cost_items_error_keys.each { |key| errors.delete(key) }
  end

  def add_localized_cost_items_errors
    cost_items.each_with_index do |cost_item, index|
      next if cost_item.marked_for_destruction? || cost_item.valid?

      add_item_errors(cost_item, index)
    end
  end

  def add_item_errors(cost_item, index)
    cost_item.errors.each do |error|
      attribute_name = CostItem.human_attribute_name(error.attribute)
      errors.add(:base, "コスト項目#{index + 1}: #{attribute_name}#{error.message}")
    end
  end
end
