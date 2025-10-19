class AddPdfHashToPatientConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_consents, :pdf_hash, :string
  end
end
