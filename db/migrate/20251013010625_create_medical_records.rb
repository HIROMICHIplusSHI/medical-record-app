class CreateMedicalRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_records do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :visit_date
      t.string :treatment_location
      t.text :chief_complaint
      t.text :diagnosis
      t.text :treatment_content
      t.text :notes

      t.timestamps
    end

    add_index :medical_records, :visit_date
    add_index :medical_records, [:user_id, :visit_date]
  end
end
