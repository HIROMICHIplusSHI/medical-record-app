class CostItem < ApplicationRecord
  belongs_to :medical_record
  belongs_to :cost_sheet, optional: true

  # バリデーション
  validates :item_name, presence: true, length: { maximum: 200 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :cost_sheet_belongs_to_same_user

  # コールバック
  before_validation :calculate_total_price

  private

  # コストシートは施術記録と同一ユーザーのものでなければならない。
  # CostSheet は dependent: :nullify のため、越境すると他ユーザーの削除操作で
  # 自分の明細が黙って書き換わる。
  def cost_sheet_belongs_to_same_user
    return if cost_sheet.nil? || medical_record.nil?

    errors.add(:cost_sheet_id, 'が不正です') if cost_sheet.user_id != medical_record.user_id
  end

  def calculate_total_price
    self.total_price = (quantity || 0) * (unit_price || 0) if quantity.present? && unit_price.present?
  end
end
