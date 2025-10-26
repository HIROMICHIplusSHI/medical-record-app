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

  describe '売上集計' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }
    let(:facility1) { create(:facility, user: user, name: '施設A') }
    let(:facility2) { create(:facility, user: user, name: '施設B') }

    before do
      # 2024年1月のデータ
      create(:medical_record, user: user, patient: patient, facility: facility1,
                              visit_date: Date.new(2024, 1, 15)) do |record|
        create(:cost_item, medical_record: record, quantity: 1, unit_price: 50_000)
      end

      create(:medical_record, user: user, patient: patient, facility: facility1,
                              visit_date: Date.new(2024, 1, 20)) do |record|
        create(:cost_item, medical_record: record, quantity: 2, unit_price: 30_000)
      end

      # 2024年2月のデータ
      create(:medical_record, user: user, patient: patient, facility: facility2,
                              visit_date: Date.new(2024, 2, 10)) do |record|
        create(:cost_item, medical_record: record, quantity: 1, unit_price: 80_000)
      end

      # 2024年3月のデータ
      create(:medical_record, user: user, patient: patient, facility: facility1,
                              visit_date: Date.new(2024, 3, 5)) do |record|
        create(:cost_item, medical_record: record, quantity: 3, unit_price: 20_000)
      end
    end

    describe '.in_period' do
      it '指定期間内のカルテを取得する' do
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 1, 31)
        records = MedicalRecord.in_period(start_date, end_date)

        expect(records.count).to eq(2)
        expect(records.pluck(:visit_date)).to all(be_between(start_date, end_date))
      end

      it '期間外のカルテは取得しない' do
        start_date = Date.new(2024, 4, 1)
        end_date = Date.new(2024, 4, 30)
        records = MedicalRecord.in_period(start_date, end_date)

        expect(records.count).to eq(0)
      end
    end

    describe '.by_user' do
      let(:other_user) { create(:user) }
      let(:other_patient) { create(:patient, user: other_user) }
      let(:other_facility) { create(:facility, user: other_user) }

      before do
        create(:medical_record, user: other_user, patient: other_patient, facility: other_facility,
                                visit_date: Date.new(2024, 1, 10))
      end

      it '指定ユーザーのカルテのみ取得する' do
        records = MedicalRecord.by_user(user.id)
        expect(records.count).to eq(4)
        expect(records.pluck(:user_id).uniq).to eq([user.id])
      end
    end

    describe '.total_revenue' do
      it '期間内の総売上を計算する' do
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 1, 31)

        total = MedicalRecord.total_revenue(start_date, end_date)
        expect(total).to eq(110_000) # 50,000 + 60,000
      end

      it '該当データがない場合は0を返す' do
        start_date = Date.new(2024, 12, 1)
        end_date = Date.new(2024, 12, 31)

        total = MedicalRecord.total_revenue(start_date, end_date)
        expect(total).to eq(0)
      end
    end

    describe '.revenue_by_facility' do
      it '施設別の売上を集計する' do
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 12, 31)

        result = MedicalRecord.revenue_by_facility(start_date, end_date)

        expect(result.count).to eq(2)

        facility1_revenue = result.find { |r| r.id == facility1.id }
        expect(facility1_revenue.name).to eq('施設A')
        expect(facility1_revenue.revenue).to eq(170_000) # 50,000 + 60,000 + 60,000

        facility2_revenue = result.find { |r| r.id == facility2.id }
        expect(facility2_revenue.name).to eq('施設B')
        expect(facility2_revenue.revenue).to eq(80_000)
      end

      it '売上の多い順に並ぶ' do
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 12, 31)

        result = MedicalRecord.revenue_by_facility(start_date, end_date)

        expect(result.first.name).to eq('施設A')
        expect(result.last.name).to eq('施設B')
      end
    end

    describe '.monthly_revenue' do
      it '指定年の月次売上を配列で返す' do
        result = MedicalRecord.monthly_revenue(2024)

        expect(result).to be_an(Array)
        expect(result.length).to eq(12)

        # 1月のデータ
        jan_data = result[0]
        expect(jan_data[:month]).to eq(1)
        expect(jan_data[:revenue]).to eq(110_000)
        expect(jan_data[:count]).to eq(2)

        # 2月のデータ
        feb_data = result[1]
        expect(feb_data[:month]).to eq(2)
        expect(feb_data[:revenue]).to eq(80_000)
        expect(feb_data[:count]).to eq(1)

        # 3月のデータ
        mar_data = result[2]
        expect(mar_data[:month]).to eq(3)
        expect(mar_data[:revenue]).to eq(60_000)
        expect(mar_data[:count]).to eq(1)

        # データがない月は0
        apr_data = result[3]
        expect(apr_data[:month]).to eq(4)
        expect(apr_data[:revenue]).to eq(0)
        expect(apr_data[:count]).to eq(0)
      end
    end

    describe '売上集計（billing_rate考慮）' do
      # 独立したテスト用ユーザーと患者を作成
      let(:billing_test_user) { create(:user) }
      let(:billing_test_patient) { create(:patient, user: billing_test_user) }

      let(:facility_100) { create(:facility, user: billing_test_user, name: '施設100%', billing_rate: 100) }
      let(:facility_80) { create(:facility, user: billing_test_user, name: '施設80%', billing_rate: 80) }
      let(:facility_50) { create(:facility, user: billing_test_user, name: '施設50%', billing_rate: 50) }
      let(:facility_0) { create(:facility, user: billing_test_user, name: '施設0%', billing_rate: 0) }
      let(:facility_nil) { create(:facility, user: billing_test_user, name: '施設nil', billing_rate: nil) }

      let!(:record_100) do
        create(:medical_record, user: billing_test_user, patient: billing_test_patient, facility: facility_100,
                                visit_date: Date.new(2024, 1, 15))
      end
      let!(:cost_item_100) do
        create(:cost_item, medical_record: record_100, item_name: '施術A', quantity: 1, unit_price: 100_000)
      end

      let!(:record_80) do
        create(:medical_record, user: billing_test_user, patient: billing_test_patient, facility: facility_80,
                                visit_date: Date.new(2024, 1, 20))
      end
      let!(:cost_item_80) do
        create(:cost_item, medical_record: record_80, item_name: '施術B', quantity: 1, unit_price: 100_000)
      end

      let!(:record_50) do
        create(:medical_record, user: billing_test_user, patient: billing_test_patient, facility: facility_50,
                                visit_date: Date.new(2024, 2, 10))
      end
      let!(:cost_item_50) do
        create(:cost_item, medical_record: record_50, item_name: '施術C', quantity: 1, unit_price: 100_000)
      end

      let!(:record_0) do
        create(:medical_record, user: billing_test_user, patient: billing_test_patient, facility: facility_0,
                                visit_date: Date.new(2024, 3, 5))
      end
      let!(:cost_item_0) do
        create(:cost_item, medical_record: record_0, item_name: '施術D', quantity: 1, unit_price: 100_000)
      end

      let!(:record_nil) do
        create(:medical_record, user: billing_test_user, patient: billing_test_patient, facility: facility_nil,
                                visit_date: Date.new(2024, 4, 12))
      end
      let!(:cost_item_nil) do
        create(:cost_item, medical_record: record_nil, item_name: '施術E', quantity: 1, unit_price: 100_000)
      end

      # 他のテストデータの影響を受けないように、このコンテキスト専用のデータのみを使用
      before do
        # 既存のテストデータをクリア（destroy_all で関連する cost_items も削除）
        MedicalRecord.where.not(user: billing_test_user).destroy_all
      end

      describe '.revenue_by_facility' do
        it 'billing_rate=100の施設は全額が売上になる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          result = MedicalRecord.revenue_by_facility(start_date, end_date).find { |r| r.name == '施設100%' }

          expect(result.total_cost).to eq(100_000)
          expect(result.billing_rate).to eq(100.0)
          expect(result.revenue).to eq(100_000)
          expect(result.record_count).to eq(1)
        end

        it 'billing_rate=80の施設は80%が売上になる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          result = MedicalRecord.revenue_by_facility(start_date, end_date).find { |r| r.name == '施設80%' }

          expect(result.total_cost).to eq(100_000)
          expect(result.billing_rate).to eq(80.0)
          expect(result.revenue).to eq(80_000)
          expect(result.record_count).to eq(1)
        end

        it 'billing_rate=50の施設は50%が売上になる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          result = MedicalRecord.revenue_by_facility(start_date, end_date).find { |r| r.name == '施設50%' }

          expect(result.total_cost).to eq(100_000)
          expect(result.billing_rate).to eq(50.0)
          expect(result.revenue).to eq(50_000)
          expect(result.record_count).to eq(1)
        end

        it 'billing_rate=0の施設は売上0になる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          result = MedicalRecord.revenue_by_facility(start_date, end_date).find { |r| r.name == '施設0%' }

          expect(result.total_cost).to eq(100_000)
          expect(result.billing_rate).to eq(0.0)
          expect(result.revenue).to eq(0)
          expect(result.record_count).to eq(1)
        end

        it 'billing_rate=nilの施設はデフォルト100%として扱われる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          result = MedicalRecord.revenue_by_facility(start_date, end_date).find { |r| r.name == '施設nil' }

          expect(result.total_cost).to eq(100_000)
          expect(result.billing_rate).to eq(100.0)
          expect(result.revenue).to eq(100_000)
          expect(result.record_count).to eq(1)
        end

        it 'total_costとrevenueが正しく区別される' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          results = MedicalRecord.revenue_by_facility(start_date, end_date)

          # 全施設のtotal_costは100,000円
          results.each do |result|
            expect(result.total_cost).to eq(100_000)
          end

          # revenueはbilling_rateによって異なる
          result_100 = results.find { |r| r.name == '施設100%' }
          result_80 = results.find { |r| r.name == '施設80%' }
          result_50 = results.find { |r| r.name == '施設50%' }
          result_0 = results.find { |r| r.name == '施設0%' }
          result_nil = results.find { |r| r.name == '施設nil' }

          expect(result_100.revenue).to eq(100_000)
          expect(result_80.revenue).to eq(80_000)
          expect(result_50.revenue).to eq(50_000)
          expect(result_0.revenue).to eq(0)
          expect(result_nil.revenue).to eq(100_000)
        end
      end

      describe '.total_revenue' do
        it '全施設の売上合計がbilling_rate適用後の金額になる' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 12, 31)

          # 期待値: 100,000 + 80,000 + 50,000 + 0 + 100,000 = 330,000
          result = MedicalRecord.total_revenue(start_date, end_date)

          expect(result).to eq(330_000)
        end

        it '期間を絞った場合、該当期間の売上のみ集計される' do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 1, 31)

          # 期待値: 1月のレコードのみ（100% + 80% = 180,000）
          result = MedicalRecord.total_revenue(start_date, end_date)

          expect(result).to eq(180_000)
        end
      end

      describe '.monthly_revenue' do
        it '各月の売上がbilling_rate適用後の金額になる' do
          result = MedicalRecord.monthly_revenue(2024)

          # 1月: 100,000 + 80,000 = 180,000
          expect(result[0][:revenue]).to eq(180_000)
          expect(result[0][:count]).to eq(2)

          # 2月: 50,000
          expect(result[1][:revenue]).to eq(50_000)
          expect(result[1][:count]).to eq(1)

          # 3月: 0
          expect(result[2][:revenue]).to eq(0)
          expect(result[2][:count]).to eq(1)

          # 4月: 100,000 (nil -> 100%)
          expect(result[3][:revenue]).to eq(100_000)
          expect(result[3][:count]).to eq(1)

          # 5月以降: 0
          (4..11).each do |month_index|
            expect(result[month_index][:revenue]).to eq(0)
            expect(result[month_index][:count]).to eq(0)
          end
        end
      end
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
