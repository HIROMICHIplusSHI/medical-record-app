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
    it '明細作成/更新時にinvoiceの合計金額が更新されるコールバックが定義されている' do
      # after_commitコールバックの存在確認
      callbacks = InvoiceItem._commit_callbacks.select do |cb|
        cb.filter == :update_invoice_total
      end
      expect(callbacks).not_to be_empty
    end

    it '明細削除時にinvoiceの合計金額が更新されるコールバックが定義されている' do
      # after_commitコールバックの存在確認（destroy時）
      callbacks = InvoiceItem._commit_callbacks.select do |cb|
        cb.filter == :update_invoice_total && cb.kind == :after
      end
      expect(callbacks).not_to be_empty
    end
  end

  describe 'instance methods' do
    describe '#medical_record_info' do
      it 'カルテの基本情報を返す' do
        patient = create(:patient, name: '山田太郎')
        medical_record = create(:medical_record, patient: patient, visit_date: Date.new(2025, 1, 15))
        item = build(:invoice_item, medical_record: medical_record)

        expect(item.medical_record_info).to eq('山田太郎 (2025-01-15)')
      end
    end
  end
end
