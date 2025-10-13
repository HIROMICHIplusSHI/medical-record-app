class DecryptExistingPatientNames < ActiveRecord::Migration[7.1]
  def up
    # 一時的にPatientモデルのコピーを作成し、暗号化を有効にして既存データを復号化
    patient_class = Class.new(ApplicationRecord) do
      self.table_name = 'patients'
      encrypts :name
    end

    patient_class.find_each do |patient|
      # 暗号化されたnameを読み取り（自動復号化される）
      decrypted_name = patient.name

      # 生のSQLで平文として保存
      ActiveRecord::Base.connection.execute(
        "UPDATE patients SET name = #{ActiveRecord::Base.connection.quote(decrypted_name)} WHERE id = #{patient.id}"
      )
    end
  end

  def down
    # downは実装しない（暗号化に戻すことはできない）
    raise ActiveRecord::IrreversibleMigration
  end
end
