class CreateMedicalRecordTags < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_record_tags do |t|
      t.references :medical_record, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :medical_record_tags, [:medical_record_id, :tag_id], unique: true
  end
end
