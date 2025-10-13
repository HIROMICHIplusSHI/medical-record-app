class MedicalRecordTag < ApplicationRecord
  belongs_to :medical_record
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :medical_record_id, message: '同じタグは1回のみ追加できます' }
end
