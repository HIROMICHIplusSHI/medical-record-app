class AddTemplateSnapshotToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :template_title, :string
  end
end
