class MedicalRecordTag < ApplicationRecord
  belongs_to :medical_record
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :medical_record_id, message: '同じタグは1回のみ追加できます' }
  validate :tag_belongs_to_same_user

  private

  # タグは施術記録と同一ユーザーのものでなければならない。
  # tag_ids= は Tag をグローバルに解決するため、他ユーザーのタグを掴めてしまう。
  # 掴まれた側はそのタグを「使用中」として削除できなくなる。
  def tag_belongs_to_same_user
    return if tag.nil? || medical_record.nil?

    errors.add(:tag_id, 'が不正です') if tag.user_id != medical_record.user_id
  end
end
