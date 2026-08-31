require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do
  describe 'associations' do
    it { should belong_to(:invoice) }
    it { should belong_to(:medical_record) }
  end

  describe 'validations' do
    subject { build(:invoice_item) }

    it { should validate_presence_of(:description) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }

    context '一意性検証' do
      it '同じinvoiceとmedical_recordの組み合わせは重複不可' do
        invoice = create(:invoice)
        medical_record = create(:medical_record)
        create(:invoice_item, invoice: invoice, medical_record: medical_record)

        duplicate_item = build(:invoice_item, invoice: invoice, medical_record: medical_record)
        expect(duplicate_item).not_to be_valid
        expect(duplicate_item.errors[:medical_record_id]).to include('はすでに存在します')
      end

      it '異なるinvoiceであれば同じmedical_recordを使用できる' do
        medical_record = create(:medical_record)
        create(:invoice_item, medical_record: medical_record)

        another_item = build(:invoice_item, medical_record: medical_record)
        expect(another_item).to be_valid
      end
    end
  end

  describe 'invoice total_amount update' do
    let(:invoice) { create(:invoice, total_amount: 0) }

    it '明細作成時にinvoiceの合計金額が自動更新される' do
      expect do
        create(:invoice_item, invoice: invoice, amount: 5000)
      end.to change { invoice.reload.total_amount }.from(0).to(5000)
    end

    it '明細更新時にinvoiceの合計金額が再計算される' do
      item = create(:invoice_item, invoice: invoice, amount: 5000)

      expect do
        item.update!(amount: 8000)
      end.to change { invoice.reload.total_amount }.from(5000).to(8000)
    end

    it '明細削除時にinvoiceの合計金額が再計算される' do
      create(:invoice_item, invoice: invoice, amount: 5000)
      item2 = create(:invoice_item, invoice: invoice, amount: 3000)

      expect do
        item2.destroy!
      end.to change { invoice.reload.total_amount }.from(8000).to(5000)
    end
  end

  describe 'instance methods' do
    describe '#medical_record_info' do
      it 'カルテの基本情報を返す' do
        patient = create(:patient, name: '山田太郎')
        medical_record = create(:medical_record, user: patient.user, patient: patient,
                                                 visit_date: Date.new(2025, 1, 15))
        item = build(:invoice_item, medical_record: medical_record)

        expect(item.medical_record_info).to eq('山田太郎 (2025-01-15)')
      end
    end
  end
end
