# 同意書PDF生成サービス
class PatientConsentPdfGenerator
  require 'prawn'
  require 'prawn/table'
  require 'stringio'

  def initialize(patient_consent)
    @consent = patient_consent
    @patient = patient_consent.patient
    @template = patient_consent.consent_form_template
    @pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
    setup_fonts
  end

  # PDFを生成してファイルパスを返す
  def generate
    build_consent_title
    build_consent_items
    build_signature
    build_facility_info

    save_pdf
  end

  # PDFを文字列として生成（プレビュー用）
  def generate_to_string
    build_consent_title
    build_consent_items
    build_signature
    build_facility_info

    @pdf.render
  end

  private

  def setup_fonts
    font_path = Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf')
    return unless File.exist?(font_path)

    begin
      @pdf.font_families.update(
        'NotoSansJP' => {
          normal: Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf').to_s,
          bold: Rails.root.join('lib', 'fonts', 'NotoSansJP-Bold.ttf').to_s,
        }
      )
      @pdf.font 'NotoSansJP'
    rescue StandardError => e
      Rails.logger.warn "日本語フォントのロードに失敗しました: #{e.message}"
    end
  end

  def build_header
    # タイトル
    @pdf.text '同意書', size: 20, style: :bold, align: :center
    @pdf.move_down 5
    @pdf.stroke_horizontal_rule
    @pdf.move_down 20
  end

  def build_basic_info
    build_consent_date
    build_facility_snapshot
    @pdf.move_down 80
  end

  def build_consent_date
    info_y = @pdf.cursor
    @pdf.text_box "同意日　　#{@consent.agreed_at.strftime('%Y年%m月%d日')}",
                  at: [@pdf.bounds.width - 200, info_y],
                  width: 200,
                  align: :right,
                  size: 9
  end

  def build_facility_snapshot
    facility_info_y = @pdf.cursor - 18

    if @consent.facility_name.present?
      @pdf.text_box "施設名　　#{@consent.facility_name}",
                    at: [@pdf.bounds.width - 200, facility_info_y],
                    width: 200,
                    align: :right,
                    size: 9
      facility_info_y -= 15
    end

    if @consent.facility_address.present?
      @pdf.text_box "住所　　　#{@consent.facility_address}",
                    at: [@pdf.bounds.width - 200, facility_info_y],
                    width: 200,
                    align: :right,
                    size: 8
      facility_info_y -= 15
    end

    return unless @consent.facility_phone.present?

    @pdf.text_box "TEL　　　#{@consent.facility_phone}",
                  at: [@pdf.bounds.width - 200, facility_info_y],
                  width: 200,
                  align: :right,
                  size: 8
  end

  def build_patient_info
    # 患者情報
    @pdf.text '【患者情報】', size: 11, style: :bold
    @pdf.move_down 8

    patient_info = []
    patient_info << ['氏名', @patient.name || '']
    patient_info << ['生年月日', @patient.date_of_birth&.strftime('%Y年%m月%d日') || '']

    @pdf.table(patient_info, width: @pdf.bounds.width, cell_style: { size: 9, padding: [4, 8] }) do
      columns(0).width = 100
      columns(0).font_style = :bold
      columns(0).background_color = 'F5F5F5'
      self.row_colors = %w[FFFFFF]
    end

    @pdf.move_down 20
  end

  def build_consent_title
    # テンプレート名を中央にタイトル表示
    @pdf.text @template.title, size: 18, style: :bold, align: :center
    @pdf.move_down 5
    @pdf.stroke_horizontal_rule
    @pdf.move_down 20
  end

  def build_consent_items
    # 同意項目リスト
    @pdf.text '【同意項目】', size: 11, style: :bold
    @pdf.move_down 8

    items_data = build_consent_items_data
    return if items_data.empty?

    @pdf.table(items_data, width: @pdf.bounds.width,
                           cell_style: {
                             size: 9, padding: [6, 8], borders: [:bottom],
                             border_width: 0.5, border_color: 'CCCCCC',
                           }) do
      columns(0).width = 40
      columns(0).align = :center
      columns(1).align = :left

      self.row_colors = %w[FFFFFF]
    end

    @pdf.move_down 20
  end

  def build_consent_items_data
    items = @template.consent_form_items.order(:position)
    checked_item_ids = @consent.consent_item_responses.select(&:checked).map(&:consent_form_item_id)

    items.map do |item|
      check_mark = checked_item_ids.include?(item.id) ? '[✓]' : '[ ]'
      [check_mark, item.content]
    end
  end

  def build_signature
    # 同意日を表示
    @pdf.text "同意日：#{@consent.agreed_at.strftime('%Y年%m月%d日')}", size: 10, align: :left
    @pdf.move_down 10

    # 署名セクション
    @pdf.text '【署名】', size: 11, style: :bold
    @pdf.move_down 8

    # 署名画像の埋め込み
    if @consent.signature_data.present? && valid_signature?
      embed_signature_image
    else
      @pdf.text '署名データがありません', size: 9
    end

    @pdf.move_down 30
  end

  def valid_signature?
    @consent.signature_data.match?(%r{\Adata:image/png;base64,[A-Za-z0-9+/=]+\z})
  end

  def embed_signature_image
    # Base64データをデコード
    parts = @consent.signature_data.split(',')
    return unless parts.length == 2

    base64_data = parts[1]
    return unless base64_data.present?

    begin
      decoded_image = Base64.strict_decode64(base64_data)

      # StringIOを使って直接埋め込み
      image_io = StringIO.new(decoded_image)

      # 画像のサイズを調整して埋め込み
      @pdf.image image_io, width: 200, position: :left
      @pdf.move_down 5
      @pdf.text '上記の通り、同意いたします。', size: 8
    rescue StandardError => e
      Rails.logger.error "署名画像の埋め込みに失敗しました: #{e.message}"
      @pdf.text '署名画像の読み込みに失敗しました', size: 9
    end
  end

  def build_facility_info
    # 施設情報を最下部に表示
    @pdf.text '【施設情報】', size: 11, style: :bold
    @pdf.move_down 8

    facility_info = []
    facility_info << ['施設名', @consent.facility_name || ''] if @consent.facility_name.present?
    facility_info << ['住所', @consent.facility_address || ''] if @consent.facility_address.present?
    facility_info << ['電話番号', @consent.facility_phone || ''] if @consent.facility_phone.present?
    facility_info << ['施術者名', @consent.practitioner_name || '']
    facility_info << ['担当医師', @consent.facility_doctor.name] if @consent.facility_doctor.present?

    @pdf.table(facility_info, width: @pdf.bounds.width, cell_style: { size: 9, padding: [4, 8] }) do
      columns(0).width = 100
      columns(0).font_style = :bold
      columns(0).background_color = 'F5F5F5'
      self.row_colors = %w[FFFFFF]
    end
  end

  def save_pdf
    pdf_dir = Rails.root.join('tmp', 'pdfs')
    FileUtils.mkdir_p(pdf_dir) unless File.directory?(pdf_dir)

    pdf_path = pdf_dir.join("patient_consent_#{@consent.id}.pdf")
    @pdf.render_file(pdf_path)

    pdf_path.to_s
  end
end
