class CreatePatientConsents < ActiveRecord::Migration[7.2]
  def change
    create_table :patient_consents do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :consent_form_template, null: false, foreign_key: true
      t.references :medical_record, null: false, foreign_key: true
      t.references :facility_doctor, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :agreed_at, null: false
      t.text :signature_data  # 暗号化
      t.text :practitioner_name  # 暗号化
      t.text :facility_name  # 暗号化
      t.text :facility_address  # 暗号化
      t.text :facility_phone  # 暗号化
      t.string :signed_ip
      t.text :signed_user_agent

      t.timestamps
    end

    add_index :patient_consents, [:medical_record_id, :consent_form_template_id],
              name: 'index_consents_on_record_and_template'
    add_index :patient_consents, :agreed_at
  end
end
