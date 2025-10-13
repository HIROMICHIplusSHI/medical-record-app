class CostSheet < ApplicationRecord
  belongs_to :user

  # カテゴリ定数
  CATEGORIES = {
    'treatment' => '施術',
    'medicine' => '薬剤',
    'supplies' => '消耗品',
    'other' => 'その他',
  }.freeze

  # バリデーション
  validates :item_name, presence: true, length: { maximum: 100 }
  validates :standard_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }

  # スコープ
  scope :by_name, -> { order(:item_name) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { category.present? ? where(category: category) : all }

  # カテゴリ名を取得
  def category_name
    CATEGORIES[category] || category
  end
end
