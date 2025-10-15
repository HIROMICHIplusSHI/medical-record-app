class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.datetime :issued_at, null: false
      t.date :billing_period_start, null: false
      t.date :billing_period_end, null: false
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :sent_at
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, [:facility_id, :billing_period_start]
    add_index :invoices, :status
  end
end
