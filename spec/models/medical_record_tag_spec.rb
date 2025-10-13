require 'rails_helper'

RSpec.describe MedicalRecordTag, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:medical_record) }
    it { should belong_to(:tag) }
  end

  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility) { create(:facility, user: user) }
    let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }
    let(:tag) { create(:tag, user: user) }

    it '同じタグは1つのカルテに1回のみ追加できる' do
      medical_record.tags << tag
      duplicate_tag = MedicalRecordTag.new(medical_record: medical_record, tag: tag)

      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors[:tag_id]).to include('同じタグは1回のみ追加できます')
    end

    it '異なるカルテには同じタグを追加できる' do
      medical_record2 = create(:medical_record, user: user, patient: patient, facility: facility)

      medical_record.tags << tag
      medical_record2.tags << tag

      expect(medical_record.tags).to include(tag)
      expect(medical_record2.tags).to include(tag)
    end
  end
end
