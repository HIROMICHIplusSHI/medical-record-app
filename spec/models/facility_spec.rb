require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }

    # MedicalRecord/Invoiceモデル実装後にテストを有効化
    # it { should have_many(:medical_records).dependent(:restrict_with_error) }
    # it { should have_many(:invoices).dependent(:restrict_with_error) }
  end

  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    context '電話番号の形式' do
      it '有効な電話番号形式を受け入れる' do
        facility = build(:facility, phone: '03-1234-5678')
        expect(facility).to be_valid
      end

      it '無効な電話番号形式を拒否する' do
        facility = build(:facility, phone: 'invalid')
        expect(facility).not_to be_valid
      end
    end

    context 'メールアドレスの形式' do
      it '有効なメールアドレス形式を受け入れる' do
        facility = build(:facility, email: 'test@example.com')
        expect(facility).to be_valid
      end

      it '無効なメールアドレス形式を拒否する' do
        facility = build(:facility, email: 'invalid')
        expect(facility).not_to be_valid
      end
    end
  end

  describe 'メソッド' do
    let(:user) { create(:user) }
    let(:facility) { create(:facility, user: user) }

    # MedicalRecordモデル実装後にテストを有効化
    xdescribe '#has_records?' do
      context '施術記録がある場合' do
        before { create(:medical_record, facility: facility, user: user) }

        it 'trueを返す' do
          expect(facility.has_records?).to be true
        end
      end

      context '施術記録がない場合' do
        it 'falseを返す' do
          expect(facility.has_records?).to be false
        end
      end
    end

    xdescribe '#total_revenue' do
      before do
        create(:medical_record, facility: facility, user: user,
                                treatment_date: Date.today, total_amount: 50_000)
        create(:medical_record, facility: facility, user: user,
                                treatment_date: Date.today - 1.day, total_amount: 30_000)
      end

      it '日付範囲なしで総売上を返す' do
        expect(facility.total_revenue).to eq(80_000)
      end

      it '日付範囲内の売上を返す' do
        expect(facility.total_revenue(Date.today, Date.today)).to eq(50_000)
      end
    end

    xdescribe '#medical_records_count' do
      before do
        create_list(:medical_record, 3, facility: facility, user: user)
      end

      it '施術記録の件数を返す' do
        expect(facility.medical_records_count).to eq(3)
      end
    end
  end
end
