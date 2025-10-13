require 'rails_helper'

RSpec.describe MedicalRecord, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:patient) }
    it { is_expected.to belong_to(:facility) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'バリデーション' do
    subject { build(:medical_record) }

    it { is_expected.to validate_presence_of(:visit_date) }
    it { is_expected.to validate_presence_of(:treatment_location) }
    it { is_expected.to validate_length_of(:treatment_location).is_at_most(200) }
    it { is_expected.to validate_presence_of(:chief_complaint) }
    it { is_expected.to validate_presence_of(:diagnosis) }
    it { is_expected.to validate_presence_of(:treatment_content) }
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility1) { create(:facility, user: user, name: '施設A') }
    let(:facility2) { create(:facility, user: user, name: '施設B') }
    let!(:record1) do
      create(:medical_record, user: user, patient: patient, facility: facility1, visit_date: 3.days.ago)
    end
    let!(:record2) { create(:medical_record, user: user, patient: patient, facility: facility2, visit_date: 1.day.ago) }
    let!(:record3) do
      create(:medical_record, user: user, patient: patient, facility: facility1, visit_date: 5.days.ago)
    end

    describe '.recent' do
      it '来院日の降順で取得できる' do
        expect(MedicalRecord.recent).to eq([record2, record1, record3])
      end
    end

    describe '.by_patient' do
      let(:other_patient) { create(:patient, user: user) }
      let!(:other_record) { create(:medical_record, user: user, patient: other_patient, facility: facility1) }

      it '指定患者のカルテのみ取得できる' do
        expect(MedicalRecord.by_patient(patient.id)).to contain_exactly(record1, record2, record3)
      end

      it 'patient_idがnilの場合は全件取得' do
        expect(MedicalRecord.by_patient(nil).count).to eq(4)
      end
    end

    describe '.by_facility' do
      it '指定施設のカルテのみ取得できる' do
        expect(MedicalRecord.by_facility(facility1.id)).to contain_exactly(record1, record3)
      end

      it 'facility_idがnilの場合は全件取得' do
        expect(MedicalRecord.by_facility(nil).count).to eq(3)
      end
    end

    describe '.by_date_range' do
      it '日付範囲でフィルタリングできる' do
        result = MedicalRecord.by_date_range(4.days.ago.to_date, 2.days.ago.to_date)
        expect(result).to contain_exactly(record1)
      end

      it '日付がnilの場合は全件取得' do
        expect(MedicalRecord.by_date_range(nil, nil).count).to eq(3)
      end
    end
  end
end
