class CreateFacilityDoctors < ActiveRecord::Migration[7.2]
  def change
    create_table :facility_doctors do |t|
      t.references :facility, null: false, foreign_key: true
      t.string :name, null: false
      t.string :medical_license_number
      t.string :specialization

      t.timestamps
    end

    add_index :facility_doctors, [:facility_id, :medical_license_number], unique: true,
              name: 'index_facility_doctors_on_facility_and_license'
  end
end
