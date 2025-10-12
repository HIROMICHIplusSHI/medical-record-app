class CreateQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    create_table :questionnaires do |t|
      t.references :patient, null: false, foreign_key: true, index: { unique: true }
      t.text :medical_history
      t.text :current_medications
      t.text :allergies
      t.text :past_surgeries
      t.text :family_history
      t.text :lifestyle_notes
      t.text :concerns

      t.timestamps
    end
  end
end
