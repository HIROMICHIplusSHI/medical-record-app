class RestructureQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    # 古いカラムを削除
    remove_column :questionnaires, :medical_history, :text
    remove_column :questionnaires, :family_history, :text
    remove_column :questionnaires, :lifestyle_notes, :text
    remove_column :questionnaires, :concerns, :text

    # 基本情報カラムを追加
    add_column :questionnaires, :full_name, :text
    add_column :questionnaires, :full_name_kana, :text
    add_column :questionnaires, :birth_date, :text
    add_column :questionnaires, :gender, :text
    add_column :questionnaires, :phone, :text
    add_column :questionnaires, :email, :text
    add_column :questionnaires, :postal_code, :text
    add_column :questionnaires, :address, :text
    add_column :questionnaires, :emergency_contact, :text

    # 医療情報カラムを追加（JSON形式）
    add_column :questionnaires, :medical_conditions, :text
    add_column :questionnaires, :pregnancy_info, :text

    # 施術情報カラムを追加（JSON形式）
    add_column :questionnaires, :desired_treatments, :text
    add_column :questionnaires, :past_treatments, :text
    add_column :questionnaires, :skin_conditions, :text
    add_column :questionnaires, :other_concerns, :text

    # 既存のカラム名を変更（より明確な名前に）
    # allergies, current_medications, past_surgeries は既存のまま使用
  end
end
