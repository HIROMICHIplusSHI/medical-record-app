class ChangeFacilityDoctorIdToOptionalInPatientConsents < ActiveRecord::Migration[7.2]
  def change
    change_column_null :patient_consents, :facility_doctor_id, true
  end
end
