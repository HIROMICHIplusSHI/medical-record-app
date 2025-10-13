class CreateCostItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_items do |t|
      t.references :medical_record, null: false, foreign_key: true, index: true
      t.string :item_name, null: false
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :cost_items, [:medical_record_id, :created_at]
  end
end
