# 請求書PDF生成サービス
class InvoicePdfGenerator
  require 'prawn'
  require 'prawn/table'

  def initialize(invoice)
    @invoice = invoice
    @facility = invoice.facility
    @user = invoice.user
    @pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
    setup_fonts
  end

  # PDFを生成してファイルパスを返す
  def generate
    build_header
    build_basic_info
    build_parties_info
    build_total_box
    build_bank_info
    build_details_table

    save_pdf
  end

  # PDFを文字列として生成（プレビュー用）
  def generate_to_string
    build_header
    build_basic_info
    build_parties_info
    build_total_box
    build_bank_info
    build_details_table

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
    # シンプルなタイトル
    @pdf.text '請求書', size: 20, style: :bold, align: :center
    @pdf.move_down 5
    @pdf.stroke_horizontal_rule
    @pdf.move_down 20
  end

  def build_basic_info
    # 右寄せで請求書番号と発行日
    info_y = @pdf.cursor
    @pdf.text_box "発行日　　#{@invoice.issued_at.strftime('%Y年%m月%d日')}",
                  at: [@pdf.bounds.width - 200, info_y],
                  width: 200,
                  align: :right,
                  size: 9

    @pdf.text_box "請求番号　#{@invoice.invoice_number}",
                  at: [@pdf.bounds.width - 200, info_y - 15],
                  width: 200,
                  align: :right,
                  size: 9

    @pdf.move_down 40
  end

  def build_parties_info
    parties_y = @pdf.cursor

    # 左側: 請求先
    addressee = @facility.billing_addressee.presence || "#{@facility.name} 御中"
    @pdf.text_box addressee,
                  at: [0, parties_y],
                  width: 250,
                  size: 12,
                  style: :bold

    parties_y -= 22
    if @facility.address.present?
      @pdf.text_box "〒#{@facility.address}",
                    at: [0, parties_y],
                    width: 250,
                    size: 9
    end

    parties_y -= 15 if @facility.address.present?
    if @facility.phone.present?
      @pdf.text_box @facility.phone,
                    at: [0, parties_y],
                    width: 250,
                    size: 9
    end

    parties_y -= 30
    @pdf.text_box '下記の通り、ご請求申し上げます。',
                  at: [0, parties_y],
                  width: 250,
                  size: 9

    # 右側: 発行者情報
    issuer_y = @pdf.cursor
    issuer_x = @pdf.bounds.width - 250

    @pdf.text_box @user.company_name.presence || '',
                  at: [issuer_x, issuer_y],
                  width: 250,
                  size: 12,
                  style: :bold,
                  align: :right

    issuer_y -= 20
    if @user.company_postal.present?
      @pdf.text_box "〒#{@user.company_postal}",
                    at: [issuer_x, issuer_y],
                    width: 250,
                    size: 9,
                    align: :right
    end

    issuer_y -= 15 if @user.company_postal.present?
    if @user.company_address.present?
      @pdf.text_box @user.company_address.to_s,
                    at: [issuer_x, issuer_y],
                    width: 250,
                    size: 9,
                    align: :right
    end

    issuer_y -= 15 if @user.company_address.present?
    if @user.company_phone.present?
      @pdf.text_box "TEL: #{@user.company_phone}",
                    at: [issuer_x, issuer_y],
                    width: 250,
                    size: 9,
                    align: :right
    end

    issuer_y -= 15 if @user.company_phone.present?
    if @user.company_email.present?
      @pdf.text_box "E-mail: #{@user.company_email}",
                    at: [issuer_x, issuer_y],
                    width: 250,
                    size: 8,
                    align: :right
    end

    @pdf.move_down 120
  end

  def build_total_box
    total_pretax = calculate_billed_amount

    if @invoice.tax_display
      # 税表示ありの場合
      tax = (total_pretax * 0.1).round
      total_with_tax = total_pretax + tax

      box_height = 60
      box_y = @pdf.cursor

      @pdf.stroke_color '000000'
      @pdf.line_width 1.5
      @pdf.stroke_rectangle [0, box_y], @pdf.bounds.width, box_height

      # 税抜き金額
      @pdf.text_box '小計（税抜）',
                    at: [10, box_y - 8],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 9,
                    align: :left

      @pdf.text_box "¥ #{number_with_delimiter(total_pretax)}",
                    at: [(@pdf.bounds.width / 2), box_y - 8],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 10,
                    align: :right

      # 消費税
      @pdf.text_box '消費税（10%）',
                    at: [10, box_y - 23],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 9,
                    align: :left

      @pdf.text_box "¥ #{number_with_delimiter(tax)}",
                    at: [(@pdf.bounds.width / 2), box_y - 23],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 10,
                    align: :right

      # 税込み合計
      @pdf.text_box 'ご請求金額（税込）',
                    at: [10, box_y - 40],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 10,
                    style: :bold,
                    align: :left

      @pdf.text_box "¥ #{number_with_delimiter(total_with_tax)}",
                    at: [(@pdf.bounds.width / 2), box_y - 40],
                    width: (@pdf.bounds.width / 2) - 10,
                    size: 14,
                    style: :bold,
                    align: :right

    else
      # 税表示なしの場合（既存）
      box_height = 42
      box_y = @pdf.cursor

      @pdf.stroke_color '000000'
      @pdf.line_width 1.5
      @pdf.stroke_rectangle [0, box_y], @pdf.bounds.width, box_height

      # ボックス内のテキスト
      @pdf.text_box 'ご請求金額',
                    at: [0, box_y - 8],
                    width: @pdf.bounds.width,
                    size: 10,
                    align: :center

      @pdf.text_box "¥ #{number_with_delimiter(total_pretax)}",
                    at: [0, box_y - 23],
                    width: @pdf.bounds.width,
                    size: 18,
                    style: :bold,
                    align: :center

    end
    @pdf.move_down box_height + 20
  end

  def build_bank_info
    return unless @user.bank_info.present?

    # シンプルなセクションヘッダー
    @pdf.text '【振込先】', size: 10, style: :bold
    @pdf.move_down 5

    # 振込先情報
    @user.bank_info.split("\n").each do |line|
      @pdf.text "　#{line}", size: 9
    end

    @pdf.move_down 15
  end

  def build_details_table
    # シンプルなセクションヘッダー
    @pdf.text '【明細】', size: 10, style: :bold
    @pdf.move_down 8

    items = @invoice.invoice_items.includes(medical_record: :patient).order('medical_records.visit_date ASC')
    return if items.empty?

    table_data = build_table_data(items)
    render_table(table_data)
  end

  def build_table_data(items)
    billing_rate = @facility.billing_rate || 100.0

    if @invoice.tax_display
      # 税表示ありバージョン
      table_data = [['日付', '患者名', '内容', '実費', '請求割合', '請求額（税抜）', '消費税（10%）', '請求額（税込）']]

      items.each do |item|
        actual_cost = item.amount || 0
        billed_amount_pretax = (actual_cost * billing_rate / 100.0).round
        tax = (billed_amount_pretax * 0.1).round
        billed_amount_with_tax = billed_amount_pretax + tax

        table_data << [
          item.medical_record.visit_date.strftime('%Y/%m/%d'),
          item.medical_record.patient.name,
          truncate_description(item.description),
          format_currency(actual_cost),
          "#{billing_rate.to_i}%",
          format_currency(billed_amount_pretax),
          format_currency(tax),
          format_currency(billed_amount_with_tax),
        ]
      end

      # 合計行
      total_actual = items.sum { |item| item.amount || 0 }
      total_billed_pretax = calculate_billed_amount
      total_tax = (total_billed_pretax * 0.1).round
      total_with_tax = total_billed_pretax + total_tax

      table_data << [
        { content: '合計', colspan: 3 },
        format_currency(total_actual),
        '',
        format_currency(total_billed_pretax),
        format_currency(total_tax),
        format_currency(total_with_tax),
      ]
    else
      # 税表示なしバージョン（既存）
      table_data = [%w[日付 患者名 内容 実費 請求割合 請求額]]

      items.each do |item|
        actual_cost = item.amount || 0
        billed_amount = (actual_cost * billing_rate / 100.0).round

        table_data << [
          item.medical_record.visit_date.strftime('%Y/%m/%d'),
          item.medical_record.patient.name,
          truncate_description(item.description),
          format_currency(actual_cost),
          "#{billing_rate.to_i}%",
          format_currency(billed_amount),
        ]
      end

      # 合計行
      total_actual = items.sum { |item| item.amount || 0 }
      total_billed = calculate_billed_amount

      table_data << [
        { content: '合計', colspan: 3 },
        format_currency(total_actual),
        '',
        format_currency(total_billed),
      ]
    end

    table_data
  end

  def render_table(table_data)
    column_count = table_data.first.size

    @pdf.table(table_data, header: true, width: @pdf.bounds.width,
                           cell_style: { size: 8, padding: [4, 5], borders: [:bottom], border_width: 0.5, border_color: 'CCCCCC' }) do
      row(0).font_style = :bold
      row(0).background_color = 'F5F5F5'
      row(0).borders = %i[top bottom]
      row(0).border_width = 1
      row(0).border_color = '000000'

      # 左寄せ列（日付、患者名、内容）
      columns(0..2).align = :left

      # 右寄せ列（金額列）
      if column_count == 8 # 税表示ありの場合
        columns(3..7).align = :right
      else # 税表示なしの場合
        columns(3..5).align = :right
      end

      row(-1).font_style = :bold
      row(-1).borders = %i[top bottom]
      row(-1).border_width = 1.5
      row(-1).border_color = '000000'
      self.row_colors = %w[FFFFFF]
      self.header = true
    end
  end

  def calculate_billed_amount
    billing_rate = @facility.billing_rate || 100.0
    total_actual = @invoice.invoice_items.sum { |item| item.amount || 0 }
    (total_actual * billing_rate / 100.0).round
  end

  def save_pdf
    pdf_dir = Rails.root.join('tmp', 'pdfs')
    FileUtils.mkdir_p(pdf_dir) unless File.directory?(pdf_dir)

    pdf_path = pdf_dir.join("invoice_#{@invoice.id}.pdf")
    @pdf.render_file(pdf_path)

    pdf_path.to_s
  end

  def format_currency(amount)
    value = (amount || 0).to_i
    "¥#{number_with_delimiter(value)}"
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def truncate_description(description)
    return '' if description.nil?

    description.length > 25 ? "#{description[0..22]}..." : description
  end
end
