require 'rails_helper'
require 'pdf-reader'

RSpec.describe InvoicePdfGenerator do
  let(:user) do
    create(:user,
           company_name: 'テスト株式会社',
           company_postal: '100-0001',
           company_address: '東京都千代田区千代田1-1',
           company_phone: '03-1234-5678',
           company_email: 'test@example.com')
  end
  let(:facility) { create(:facility, user: user, name: 'テスト施設', billing_rate: 100) }
  let(:invoice) do
    create(:invoice,
           user: user,
           facility: facility,
           billing_period_start: Date.new(2025, 1, 1),
           billing_period_end: Date.new(2025, 1, 31))
  end
  let(:generator) { described_class.new(invoice) }

  describe '#generate' do
    context '正常系' do
      let(:patient) { create(:patient, user: user, name: '山田太郎') }
      let(:medical_record) do
        create(:medical_record,
               user: user,
               facility: facility,
               patient: patient,
               visit_date: Date.new(2025, 1, 15))
      end

      before do
        create(:invoice_item,
               invoice: invoice,
               medical_record: medical_record,
               description: 'テスト診療',
               amount: 10_000)
      end

      it 'PDFファイルが生成される' do
        pdf_path = generator.generate
        expect(File.exist?(pdf_path)).to be true
      end

      it 'PDFファイルサイズが0より大きい' do
        pdf_path = generator.generate
        expect(File.size(pdf_path)).to be > 0
      end

      it '生成されたPDFが有効なPDF形式である' do
        pdf_path = generator.generate
        reader = PDF::Reader.new(pdf_path)
        expect(reader.page_count).to be > 0
      end

      it 'PDFファイル名にinvoice IDが含まれる' do
        pdf_path = generator.generate
        expect(pdf_path).to include("invoice_#{invoice.id}.pdf")
      end
    end

    context 'フォントファイルが存在しない場合' do
      let(:patient) { create(:patient, user: user) }
      let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

      before do
        create(:invoice_item, invoice: invoice, medical_record: medical_record)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(
          Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf')
        ).and_return(false)
      end

      it 'PDF生成が失敗する（日本語文字列と互換性エラー）' do
        expect do
          generator.generate
        end.to raise_error(Prawn::Errors::IncompatibleStringEncoding)
      end
    end
  end

  describe '#generate_to_string' do
    let(:patient) { create(:patient, user: user, name: '田中花子') }
    let(:medical_record) do
      create(:medical_record,
             user: user,
             facility: facility,
             patient: patient,
             visit_date: Date.new(2025, 1, 20))
    end

    before do
      create(:invoice_item,
             invoice: invoice,
             medical_record: medical_record,
             description: '外来診療',
             amount: 5_000)
    end

    it 'PDFバイナリ文字列を返す' do
      pdf_string = generator.generate_to_string
      expect(pdf_string).to be_a(String)
      expect(pdf_string.bytesize).to be > 0
    end

    it '返されたバイナリが有効なPDF形式である' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      expect(reader.page_count).to be > 0
    end

    it 'ファイルシステムに書き込まない' do
      pdf_path = Rails.root.join('tmp', 'pdfs', "invoice_#{invoice.id}.pdf")
      FileUtils.rm_f(pdf_path)

      generator.generate_to_string

      expect(File.exist?(pdf_path)).to be false
    end
  end

  describe 'PDFコンテンツ検証' do
    let(:patient) { create(:patient, user: user, name: '鈴木一郎') }
    let(:medical_record) do
      create(:medical_record,
             user: user,
             facility: facility,
             patient: patient,
             visit_date: Date.new(2025, 1, 10))
    end

    before do
      create(:invoice_item,
             invoice: invoice,
             medical_record: medical_record,
             description: '初診料',
             amount: 15_000)
    end

    it '請求書番号が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      expect(text).to include(invoice.invoice_number)
    end

    it '施設名が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      expect(text).to include(facility.name)
    end

    it '患者名が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      expect(text).to include('鈴木一郎')
    end

    it '請求額が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      # 15,000円の表示を確認
      expect(text).to include('15,000')
    end

    it '会社情報が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      expect(text).to include('テスト株式会社')
    end
  end

  describe '税表示切替' do
    let(:patient) { create(:patient, user: user) }
    let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

    before do
      create(:invoice_item, invoice: invoice, medical_record: medical_record, amount: 10_000)
    end

    context '税表示なしの場合' do
      before { invoice.update(tax_display: false) }

      it '消費税の文字列が含まれない' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        expect(text).not_to include('消費税')
      end
    end

    context '税表示ありの場合' do
      before { invoice.update(tax_display: true) }

      it '消費税の文字列が含まれる' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        expect(text).to include('消費税（10%）')
      end

      it '税込み合計が計算される' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        # 10,000円 + 消費税10% = 11,000円
        expect(text).to include('11,000')
      end
    end
  end

  describe '請求割合計算' do
    let(:patient) { create(:patient, user: user) }
    let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

    before do
      create(:invoice_item, invoice: invoice, medical_record: medical_record, amount: 10_000)
    end

    context '請求割合が80%の場合' do
      before { facility.update(billing_rate: 80) }

      it '80%の金額が表示される' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        # 10,000円 * 80% = 8,000円
        expect(text).to include('8,000')
      end
    end

    context '請求割合が50%の場合' do
      before { facility.update(billing_rate: 50) }

      it '50%の金額が表示される' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        # 10,000円 * 50% = 5,000円
        expect(text).to include('5,000')
      end
    end
  end

  describe '複数明細の処理' do
    let(:patient1) { create(:patient, user: user, name: '患者A') }
    let(:patient2) { create(:patient, user: user, name: '患者B') }
    let(:medical_record1) { create(:medical_record, user: user, facility: facility, patient: patient1) }
    let(:medical_record2) { create(:medical_record, user: user, facility: facility, patient: patient2) }

    before do
      create(:invoice_item,
             invoice: invoice,
             medical_record: medical_record1,
             description: '診療A',
             amount: 3_000)
      create(:invoice_item,
             invoice: invoice,
             medical_record: medical_record2,
             description: '診療B',
             amount: 7_000)
    end

    it '複数の患者名が含まれる' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      expect(text).to include('患者A')
      expect(text).to include('患者B')
    end

    it '合計金額が正しく計算される' do
      pdf_string = generator.generate_to_string
      reader = PDF::Reader.new(StringIO.new(pdf_string))
      text = reader.pages.map(&:text).join
      # 3,000 + 7,000 = 10,000
      expect(text).to include('10,000')
    end
  end

  describe '説明文の切り詰め処理' do
    let(:patient) { create(:patient, user: user) }
    let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

    before do
      long_description = 'あ' * 30 # 25文字を超える
      create(:invoice_item,
             invoice: invoice,
             medical_record: medical_record,
             description: long_description,
             amount: 1_000)
    end

    it 'PDFが生成できる（切り詰め処理が機能）' do
      expect do
        generator.generate_to_string
      end.not_to raise_error
    end
  end

  describe 'エッジケース' do
    context '請求明細が0円の場合' do
      let(:patient) { create(:patient, user: user) }
      let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

      before do
        create(:invoice_item, invoice: invoice, medical_record: medical_record, amount: 0)
      end

      it 'PDFが生成できる' do
        expect do
          generator.generate_to_string
        end.not_to raise_error
      end

      it '0円が表示される' do
        pdf_string = generator.generate_to_string
        reader = PDF::Reader.new(StringIO.new(pdf_string))
        text = reader.pages.map(&:text).join
        expect(text).to include('0')
      end
    end

    context '特殊文字を含む患者名' do
      let(:patient) { create(:patient, user: user, name: '山田　太郎（仮名）') }
      let(:medical_record) { create(:medical_record, user: user, facility: facility, patient: patient) }

      before do
        create(:invoice_item, invoice: invoice, medical_record: medical_record, amount: 1_000)
      end

      it 'PDFが生成できる' do
        expect do
          generator.generate_to_string
        end.not_to raise_error
      end
    end

    context '会社情報が未設定の場合' do
      before do
        user.update(company_name: nil, company_address: nil)
        patient = create(:patient, user: user)
        medical_record = create(:medical_record, user: user, facility: facility, patient: patient)
        create(:invoice_item, invoice: invoice, medical_record: medical_record, amount: 1_000)
      end

      it 'PDFが生成できる' do
        expect do
          generator.generate_to_string
        end.not_to raise_error
      end
    end
  end
end
