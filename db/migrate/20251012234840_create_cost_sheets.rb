class CreateCostSheets < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_sheets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_name, null: false
      t.integer :standard_price, null: false, default: 0
      t.string :category
      t.text :memo

      t.timestamps
    end

    add_index :cost_sheets, :category
    add_index :cost_sheets, :item_name
  end
end
