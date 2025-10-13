require 'rails_helper'

RSpec.describe MedicalRecord, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:patient) }
    it { is_expected.to belong_to(:facility) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:cost_items).dependent(:destroy) }
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

  describe '#total_cost' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility) { create(:facility, user: user) }
    let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

    it 'コスト項目がない場合は0を返す' do
      expect(medical_record.total_cost).to eq(0)
    end

    it 'コスト項目の合計金額を正しく計算する' do
      create(:cost_item, medical_record: medical_record, quantity: 2, unit_price: 30_000)
      create(:cost_item, medical_record: medical_record, quantity: 1, unit_price: 50_000)
      expect(medical_record.total_cost).to eq(110_000)
    end
  end

  describe '画像アタッチメント' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility) { create(:facility, user: user) }
    let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

    it '画像を添付できる' do
      medical_record.photos.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
        filename: 'sample_image.jpg',
        content_type: 'image/jpeg'
      )
      expect(medical_record.photos).to be_attached
      expect(medical_record.photos.count).to eq(1)
    end

    it '複数の画像を添付できる' do
      3.times do |i|
        medical_record.photos.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
          filename: "image_#{i}.jpg",
          content_type: 'image/jpeg'
        )
      end
      expect(medical_record.photos.count).to eq(3)
    end

    it '6枚以上の画像は添付できない' do
      6.times do |i|
        medical_record.photos.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
          filename: "image_#{i}.jpg",
          content_type: 'image/jpeg'
        )
      end
      expect(medical_record).not_to be_valid
      expect(medical_record.errors[:photos]).to include('は最大5枚までアップロードできます')
    end

    it '10MBを超える画像は添付できない' do
      # ActiveStorage::Blobを直接作成してサイズを設定
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('a' * 100), # 小さいダミーデータ
        filename: 'large_image.jpg',
        content_type: 'image/jpeg'
      )
      # byte_sizeを11MBに設定（DBレベルで変更）
      blob.update_column(:byte_size, 11.megabytes)

      medical_record.photos.attach(blob)

      expect(medical_record).not_to be_valid
      expect(medical_record.errors[:photos]).to include('large_image.jpgのサイズが10MBを超えています')
    end
  end

  describe 'nested attributes' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility) { create(:facility, user: user) }

    it 'コスト項目を含めてカルテを作成できる' do
      medical_record = MedicalRecord.new(
        user: user,
        patient: patient,
        facility: facility,
        visit_date: Date.today,
        treatment_location: '顔',
        chief_complaint: 'しわ',
        diagnosis: '老化',
        treatment_content: 'ボトックス',
        cost_items_attributes: [
          { item_name: 'ボトックス注射', quantity: 1, unit_price: 50_000 },
          { item_name: 'ヒアルロン酸注射', quantity: 2, unit_price: 30_000 },
        ]
      )

      expect(medical_record.save).to be true
      expect(medical_record.cost_items.count).to eq(2)
      expect(medical_record.total_cost).to eq(110_000)
    end

    it 'コスト項目を更新できる' do
      medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
      cost_item = create(:cost_item, medical_record: medical_record, item_name: 'テスト項目', quantity: 1,
                                     unit_price: 50_000)
      medical_record.reload

      medical_record.update(
        cost_items_attributes: [
          { id: cost_item.id, item_name: 'テスト項目', quantity: 3, unit_price: 40_000 },
        ]
      )

      cost_item.reload
      expect(cost_item.quantity).to eq(3)
      expect(cost_item.unit_price).to eq(40_000)
      expect(cost_item.total_price).to eq(120_000)
    end

    it 'コスト項目を削除できる' do
      medical_record = create(:medical_record, user: user, patient: patient, facility: facility)
      cost_item = create(:cost_item, medical_record: medical_record, item_name: 'テスト項目', quantity: 1,
                                     unit_price: 10_000)
      medical_record.reload

      expect do
        medical_record.update(
          cost_items_attributes: [
            { id: cost_item.id, _destroy: '1' },
          ]
        )
      end.to change(CostItem, :count).by(-1)
    end
  end
end
