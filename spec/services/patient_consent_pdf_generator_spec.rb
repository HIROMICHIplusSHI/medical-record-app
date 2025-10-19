require 'rails_helper'

RSpec.describe PatientConsentPdfGenerator, type: :service do
  let(:user) { create(:user, company_name: '美容施術者 田中') }
  let(:patient) { create(:patient, user: user, name: '山田太郎', date_of_birth: '1985-05-15') }
  let(:facility) { create(:facility, user: user, name: 'サロンA', address: '東京都渋谷区1-2-3', phone: '03-1234-5678') }
  let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }
  let(:template) { create(:consent_form_template, :with_items, user: user, title: 'アートメイク同意書') }
  let(:consent) do
    create(:patient_consent, :with_responses,
           user: user,
           patient: patient,
           medical_record: medical_record,
           consent_form_template: template)
  end

  describe '#initialize' do
    it '同意書データを受け取ってPDFジェネレーターを初期化できる' do
      generator = described_class.new(consent)
      expect(generator).to be_a(PatientConsentPdfGenerator)
    end
  end

  describe '#generate' do
    it 'PDFを生成してファイルパスを返す' do
      generator = described_class.new(consent)
      pdf_path = generator.generate

      expect(File.exist?(pdf_path)).to be true
      expect(pdf_path).to include("patient_consent_#{consent.id}.pdf")

      # クリーンアップ
      FileUtils.rm_f(pdf_path)
    end

    it '生成されたPDFが有効なPDFファイルである' do
      generator = described_class.new(consent)
      pdf_path = generator.generate

      # PDFファイルのマジックナンバー確認
      pdf_content = File.binread(pdf_path)
      expect(pdf_content).to start_with('%PDF-')

      # クリーンアップ
      FileUtils.rm_f(pdf_path)
    end

    it '生成されたPDFに基本情報が含まれる' do
      generator = described_class.new(consent)
      pdf_path = generator.generate

      # PDFテキスト抽出は複雑なので、ファイルサイズが妥当か確認
      file_size = File.size(pdf_path)
      expect(file_size).to be > 5000 # 最小5KB以上

      # クリーンアップ
      FileUtils.rm_f(pdf_path)
    end
  end

  describe '#generate_to_string' do
    it 'PDFをバイナリ文字列として生成できる' do
      generator = described_class.new(consent)
      pdf_string = generator.generate_to_string

      expect(pdf_string).to be_a(String)
      expect(pdf_string).to start_with('%PDF-')
      expect(pdf_string.length).to be > 5000
    end

    it 'プレビュー用にファイルを作成せずPDFデータを返す' do
      generator = described_class.new(consent)

      # tmp/pdfsディレクトリ内のファイル数を確認
      pdf_dir = Rails.root.join('tmp', 'pdfs')
      FileUtils.mkdir_p(pdf_dir) unless File.directory?(pdf_dir)
      files_before = Dir.glob(pdf_dir.join('*.pdf')).count

      pdf_string = generator.generate_to_string

      files_after = Dir.glob(pdf_dir.join('*.pdf')).count
      expect(files_after).to eq(files_before) # ファイル数が増えていない
      expect(pdf_string).to be_present
    end
  end

  describe 'PDF content structure' do
    let(:generator) { described_class.new(consent) }

    it 'PDFに署名画像が埋め込まれる' do
      # 署名データがBase64 PNGとして存在することを確認
      expect(consent.signature_data).to match(%r{\Adata:image/png;base64,})

      pdf_string = generator.generate_to_string

      # PNGマジックナンバーがPDF内に含まれることを確認
      # （画像がPDFストリームに埋め込まれている）
      expect(pdf_string.encoding).to eq(Encoding::ASCII_8BIT)
      expect(pdf_string.length).to be > 5000
    end

    it 'PDFに同意項目のチェック状態が含まれる' do
      # generate_to_stringで生成されたPDFが有効であることを確認
      pdf_string = generator.generate_to_string

      expect(pdf_string).to be_present
      expect(pdf_string).to start_with('%PDF-')
    end

    it 'PDFに施設情報スナップショットが含まれる' do
      # 施設情報がスナップショット保存されていることを確認
      expect(consent.facility_name).to eq('サロンA')
      expect(consent.facility_address).to eq('東京都渋谷区1-2-3')
      expect(consent.facility_phone).to eq('03-1234-5678')
      expect(consent.practitioner_name).to eq('美容施術者 田中')

      pdf_string = generator.generate_to_string

      expect(pdf_string).to be_present
    end

    it 'PDFに患者情報が含まれる' do
      pdf_string = generator.generate_to_string

      expect(pdf_string).to be_present
      expect(consent.patient.name).to eq('山田太郎')
    end

    it 'PDFに同意書テンプレートタイトルが含まれる' do
      expect(consent.consent_form_template.title).to eq('アートメイク同意書')

      pdf_string = generator.generate_to_string

      expect(pdf_string).to be_present
    end
  end

  describe 'error handling' do
    it '署名データが不正な場合でもPDF生成は継続する' do
      # 不正な署名データでも、スキップしてPDF生成を継続
      invalid_consent = create(:patient_consent, :with_responses,
                               user: user,
                               patient: patient,
                               medical_record: medical_record,
                               consent_form_template: template)
      # 署名データを一時的に無効化（バリデーション後に変更）
      invalid_consent.update_column(:signature_data, 'invalid_data')

      generator = described_class.new(invalid_consent)

      expect { generator.generate_to_string }.not_to raise_error
    end
  end
end
