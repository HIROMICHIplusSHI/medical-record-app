class AddNurseConfirmedToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :nurse_confirmed, :boolean, default: false, null: false
  end
end
