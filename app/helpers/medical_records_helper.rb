# 施術記録（MedicalRecord）の表示に関するヘルパー。
module MedicalRecordsHelper
  # 施術記録一覧の検索・クリアの遷移先を、現在のスコープに合わせて返す。
  # 患者ネスト（/patients/:patient_id/medical_records）ではその患者の履歴に留まる。
  def medical_records_scope_path(patient)
    patient ? patient_medical_records_path(patient) : medical_records_path
  end

  # フォームのキャンセル先。
  # 編集中は元の施術記録へ、患者起点の新規作成はその患者へ、それ以外は一覧へ戻す。
  def medical_record_form_cancel_path(record, patient = nil)
    return record if record.persisted?
    return patient_path(patient) if patient

    medical_records_path
  end
end
