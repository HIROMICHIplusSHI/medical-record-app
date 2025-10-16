class AddTaxDisplayToInvoices < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :tax_display, :boolean, default: false, null: false
  end
end
