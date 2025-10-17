require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:facility) }
    it { should have_many(:invoice_items).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:invoice) }

    it { should validate_uniqueness_of(:invoice_number) }
    it { should validate_presence_of(:issued_at) }
    it { should validate_presence_of(:billing_period_start) }
    it { should validate_presence_of(:billing_period_end) }
    it { should validate_numericality_of(:total_amount).is_greater_than_or_equal_to(0) }

    context '請求期間の妥当性検証' do
      it '請求期間終了日が開始日より前の場合は無効' do
        invoice = build(:invoice, billing_period_start: Date.current, billing_period_end: Date.current - 1.day)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:billing_period_end]).to include('は請求期間開始日以降の日付を指定してください')
      end

      it '請求期間終了日が開始日と同じ場合は有効' do
        invoice = build(:invoice, billing_period_start: Date.current, billing_period_end: Date.current)
        expect(invoice).to be_valid
      end

      it '請求期間終了日が開始日より後の場合は有効' do
        invoice = build(:invoice, billing_period_start: Date.current, billing_period_end: Date.current + 1.day)
        expect(invoice).to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, issued: 1, sent: 2, paid: 3, cancelled: 4) }
  end

  describe 'callbacks' do
    describe 'before_validation' do
      context 'invoice_numberが空の場合' do
        it '請求書番号を自動生成する' do
          invoice = build(:invoice, invoice_number: nil)
          invoice.valid?
          expect(invoice.invoice_number).to match(/\AINV-\d{6}-\d{4}\z/)
        end

        it '請求書番号が一意である' do
          create(:invoice, invoice_number: 'INV-202510-0001')
          invoice = build(:invoice, invoice_number: nil)
          invoice.valid?
          expect(invoice.invoice_number).not_to eq('INV-202510-0001')
        end
      end

      context 'invoice_numberが既に設定されている場合' do
        it '請求書番号を上書きしない' do
          invoice = build(:invoice, invoice_number: 'CUSTOM-001')
          invoice.valid?
          expect(invoice.invoice_number).to eq('CUSTOM-001')
        end
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it '最新の請求書を返す' do
        create(:invoice, issued_at: 2.days.ago)
        new_invoice = create(:invoice, issued_at: 1.day.ago)
        expect(Invoice.recent.first).to eq(new_invoice)
      end
    end

    describe '.by_status' do
      it '指定されたステータスの請求書を返す' do
        draft_invoice = create(:invoice, status: :draft)
        issued_invoice = create(:invoice, status: :issued)
        expect(Invoice.by_status(:draft)).to include(draft_invoice)
        expect(Invoice.by_status(:draft)).not_to include(issued_invoice)
      end
    end

    describe '.by_facility' do
      it '指定された施設の請求書を返す' do
        facility1 = create(:facility)
        facility2 = create(:facility)
        invoice1 = create(:invoice, facility: facility1)
        invoice2 = create(:invoice, facility: facility2)
        expect(Invoice.by_facility(facility1.id)).to include(invoice1)
        expect(Invoice.by_facility(facility1.id)).not_to include(invoice2)
      end
    end

    describe '.by_period' do
      it '指定された期間の請求書を返す' do
        invoice1 = create(:invoice, billing_period_start: Date.new(2025, 1, 1),
                                    billing_period_end: Date.new(2025, 1, 31))
        invoice2 = create(:invoice, billing_period_start: Date.new(2025, 2, 1),
                                    billing_period_end: Date.new(2025, 2, 28))
        result = Invoice.by_period(Date.new(2025, 1, 1), Date.new(2025, 1, 31))
        expect(result).to include(invoice1)
        expect(result).not_to include(invoice2)
      end
    end
  end

  describe 'instance methods' do
    describe '#calculate_total_amount' do
      it '請求書明細の合計金額を計算する' do
        invoice = create(:invoice, :with_items)
        expect(invoice.calculate_total_amount).to eq(invoice.invoice_items.sum(:amount))
      end

      it '明細がない場合は0を返す' do
        invoice = create(:invoice)
        expect(invoice.calculate_total_amount).to eq(0)
      end
    end

    describe '#update_total_amount!' do
      it '合計金額を再計算して保存する' do
        invoice = create(:invoice)
        create(:invoice_item, invoice: invoice, amount: 5000)
        create(:invoice_item, invoice: invoice, amount: 3000)
        invoice.update_total_amount!
        expect(invoice.reload.total_amount).to eq(8000)
      end
    end

    describe '#billed_amount' do
      it '請求割合が100%の場合、実費と同額を返す' do
        facility = create(:facility, billing_rate: 100)
        invoice = create(:invoice, facility: facility, total_amount: 10_000)
        expect(invoice.billed_amount).to eq(10_000)
      end

      it '請求割合が80%の場合、実費の80%を返す' do
        facility = create(:facility, billing_rate: 80)
        invoice = create(:invoice, facility: facility, total_amount: 10_000)
        expect(invoice.billed_amount).to eq(8000)
      end

      it '請求割合が50%の場合、実費の50%を返す' do
        facility = create(:facility, billing_rate: 50)
        invoice = create(:invoice, facility: facility, total_amount: 10_000)
        expect(invoice.billed_amount).to eq(5000)
      end

      it '請求割合が未設定（nil）の場合、実費と同額（100%）を返す' do
        facility = create(:facility, billing_rate: nil)
        invoice = create(:invoice, facility: facility, total_amount: 10_000)
        expect(invoice.billed_amount).to eq(10_000)
      end

      it '端数が出る場合は四捨五入される' do
        facility = create(:facility, billing_rate: 33.33)
        invoice = create(:invoice, facility: facility, total_amount: 10_000)
        expect(invoice.billed_amount).to eq(3333) # 10000 * 0.3333 = 3333.0
      end
    end

    describe '#period' do
      it '請求期間を文字列で返す' do
        invoice = build(:invoice, billing_period_start: Date.new(2025, 1, 1), billing_period_end: Date.new(2025, 1, 31))
        expect(invoice.period).to eq('2025-01-01 ~ 2025-01-31')
      end
    end

    describe '#can_edit?' do
      it 'draft状態の場合はtrueを返す' do
        invoice = build(:invoice, status: :draft)
        expect(invoice.can_edit?).to be true
      end

      it 'issued状態の場合はtrueを返す' do
        invoice = build(:invoice, status: :issued)
        expect(invoice.can_edit?).to be true
      end

      it 'sent状態の場合はfalseを返す' do
        invoice = build(:invoice, status: :sent)
        expect(invoice.can_edit?).to be false
      end

      it 'paid状態の場合はfalseを返す' do
        invoice = build(:invoice, status: :paid)
        expect(invoice.can_edit?).to be false
      end

      it 'cancelled状態の場合はfalseを返す' do
        invoice = build(:invoice, status: :cancelled)
        expect(invoice.can_edit?).to be false
      end
    end

    describe '#can_delete?' do
      it 'draft状態の場合はtrueを返す' do
        invoice = build(:invoice, status: :draft)
        expect(invoice.can_delete?).to be true
      end

      it 'draft以外の状態の場合はfalseを返す' do
        invoice = build(:invoice, status: :issued)
        expect(invoice.can_delete?).to be false
      end
    end
  end

  describe 'ransackable' do
    it 'ransackable_attributes を定義している' do
      expect(Invoice.ransackable_attributes).to include('invoice_number', 'status', 'issued_at',
                                                        'billing_period_start', 'billing_period_end')
    end

    it 'ransackable_associations を定義している' do
      expect(Invoice.ransackable_associations).to include('user', 'facility', 'invoice_items')
    end
  end

  describe '並行処理対策' do
    it '請求書番号が自動生成される' do
      invoice = build(:invoice, invoice_number: nil)
      invoice.valid?
      expect(invoice.invoice_number).to match(/\AINV-\d{6}-\d{4}\z/)
    end

    it '同じ月内で連続して請求書を作成すると番号が増加する' do
      # 連続して請求書を作成
      invoice1 = create(:invoice, invoice_number: nil)
      invoice2 = create(:invoice, invoice_number: nil)
      invoice3 = create(:invoice, invoice_number: nil)

      # 番号が全て異なり、増加していることを確認
      numbers = [invoice1, invoice2, invoice3].map(&:invoice_number)
      expect(numbers.uniq.size).to eq(3)

      # 番号の末尾が増加していることを確認
      last_digits = numbers.map { |n| n.match(/-(\d{4})\z/)[1].to_i }
      expect(last_digits).to eq(last_digits.sort)
    end
  end
end
