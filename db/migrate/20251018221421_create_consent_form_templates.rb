class CreateConsentFormTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :consent_form_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :consent_form_templates, [:user_id, :title], unique: true
  end
end
