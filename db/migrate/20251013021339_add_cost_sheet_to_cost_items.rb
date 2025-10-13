class AddCostSheetToCostItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :cost_items, :cost_sheet, null: true, foreign_key: true
  end
end
