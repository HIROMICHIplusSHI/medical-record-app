class AddBillingInfoToFacilities < ActiveRecord::Migration[7.2]
  def change
    add_column :facilities, :billing_addressee, :string
    add_column :facilities, :billing_rate, :decimal
  end
end
