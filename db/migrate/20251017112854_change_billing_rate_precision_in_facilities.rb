class ChangeBillingRatePrecisionInFacilities < ActiveRecord::Migration[7.2]
  def up
    change_column :facilities, :billing_rate, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :facilities, :billing_rate, :decimal
  end
end
