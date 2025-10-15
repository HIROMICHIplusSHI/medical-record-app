class CreateInvoiceItems < ActiveRecord::Migration[7.2]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :medical_record, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, default: 0.0, null: false

      t.timestamps
    end

    add_index :invoice_items, [:invoice_id, :medical_record_id], unique: true, name: 'index_invoice_items_on_invoice_and_medical_record'
  end
end
