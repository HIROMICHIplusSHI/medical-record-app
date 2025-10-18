class CreateConsentFormItems < ActiveRecord::Migration[7.2]
  def change
    create_table :consent_form_items do |t|
      t.references :consent_form_template, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false
      t.boolean :is_required, default: true, null: false

      t.timestamps
    end

    add_index :consent_form_items, [:consent_form_template_id, :position]
  end
end
