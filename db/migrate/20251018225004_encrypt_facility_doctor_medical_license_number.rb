class EncryptFacilityDoctorMedicalLicenseNumber < ActiveRecord::Migration[7.2]
  def change
    # FacilityDoctorモデルのmedical_license_numberを暗号化
    # Active Record Encryptionはモデルレベルで設定するため、
    # カラム定義の変更は不要（既存のstringカラムをそのまま使用）
    #
    # モデル側で以下を設定:
    # encrypts :medical_license_number, deterministic: true
    #
    # deterministic: true により、検索とユニーク制約が機能する
  end
end
