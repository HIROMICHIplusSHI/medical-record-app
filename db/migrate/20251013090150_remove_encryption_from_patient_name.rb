class RemoveEncryptionFromPatientName < ActiveRecord::Migration[7.1]
  def up
    # 患者名検索のためのインデックスを追加
    # Active Record Encryptionは透過的に動作するため、
    # モデルからencrypts :nameを削除するだけで自動的に平文として扱われる
    add_index :patients, :name unless index_exists?(:patients, :name)
  end

  def down
    remove_index :patients, :name if index_exists?(:patients, :name)
  end
end
