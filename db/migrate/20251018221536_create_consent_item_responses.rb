class CreateConsentItemResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :consent_item_responses do |t|
      t.references :patient_consent, null: false, foreign_key: true
      t.references :consent_form_item, null: false, foreign_key: true
      t.boolean :checked, default: false, null: false

      t.timestamps
    end

    add_index :consent_item_responses, [:patient_consent_id, :consent_form_item_id],
              unique: true, name: 'index_consent_responses_uniqueness'
  end
end
