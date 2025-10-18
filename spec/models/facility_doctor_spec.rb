require 'rails_helper'

RSpec.describe FacilityDoctor, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:facility) }
    it { is_expected.to have_many(:patient_consents) }
  end

  describe 'バリデーション' do
    subject { build(:facility_doctor) }

    it { is_expected.to validate_presence_of(:name) }

    context '医師免許番号のユニーク性' do
      it '同じ施設内で医師免許番号が重複する場合、エラーになる' do
        facility = create(:facility)
        create(:facility_doctor, facility: facility, medical_license_number: '医123456')
        duplicate_doctor = build(:facility_doctor, facility: facility, medical_license_number: '医123456')

        expect(duplicate_doctor).not_to be_valid
        expect(duplicate_doctor.errors[:medical_license_number]).to include('はすでに存在します')
      end

      it '異なる施設であれば同じ医師免許番号でも許可される' do
        facility1 = create(:facility)
        facility2 = create(:facility)
        create(:facility_doctor, facility: facility1, medical_license_number: '医123456')
        duplicate_doctor = build(:facility_doctor, facility: facility2, medical_license_number: '医123456')

        expect(duplicate_doctor).to be_valid
      end

      it '医師免許番号がnilの場合は重複チェックをスキップする' do
        facility = create(:facility)
        create(:facility_doctor, facility: facility, medical_license_number: nil)
        duplicate_doctor = build(:facility_doctor, facility: facility, medical_license_number: nil)

        expect(duplicate_doctor).to be_valid
      end
    end
  end

  describe '#display_name' do
    context '医師免許番号がある場合' do
      it '名前と医師免許番号を組み合わせた文字列を返す' do
        doctor = build(:facility_doctor, name: '山田太郎医師', medical_license_number: '医123456')
        expect(doctor.display_name).to eq('山田太郎医師 (医123456)')
      end
    end

    context '医師免許番号がない場合' do
      it '名前のみを返す' do
        doctor = build(:facility_doctor, name: '山田太郎医師', medical_license_number: nil)
        expect(doctor.display_name).to eq('山田太郎医師')
      end
    end
  end
end
