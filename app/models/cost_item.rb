class CostItem < ApplicationRecord
  belongs_to :medical_record

  # バリデーション
  validates :item_name, presence: true, length: { maximum: 200 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # コールバック
  before_validation :calculate_total_price

  private

  def calculate_total_price
    self.total_price = (quantity || 0) * (unit_price || 0) if quantity.present? && unit_price.present?
  end
end
