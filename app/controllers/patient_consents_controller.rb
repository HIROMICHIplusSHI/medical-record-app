class PatientConsentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record
  before_action :set_patient_consent, only: %i[show generate_pdf download_pdf preview_pdf destroy]
  before_action :set_patient_consents, only: [:index]

  # GET /medical_records/:medical_record_id/patient_consents
  def index
    @patient_consents = @medical_record.patient_consents
                                       .includes(
                                         :consent_form_template,
                                         :facility_doctor,
                                         consent_item_responses: :consent_form_item
                                       )
                                       .recent
  end

  # GET /medical_records/:medical_record_id/patient_consents/new
  def new
    @consent_form_templates = current_user.consent_form_templates
                                          .includes(:consent_form_items)
                                          .order(created_at: :desc)
    @facility_doctors = @medical_record.facility.facility_doctors.order(:name)
  end

  # POST /medical_records/:medical_record_id/patient_consents
  def create
    @consents_data = params[:patient_consents] || {}
    @created_consents = []
    errors = []

    process_consent_creation(errors)
    handle_creation_result(errors)
  end

  # GET /medical_records/:medical_record_id/patient_consents/:id
  def show
    # eager loading済み（set_patient_consent）
  end

  # POST /medical_records/:medical_record_id/patient_consents/:id/generate_pdf
  def generate_pdf
    # PDF生成サービスを呼び出し
    PatientConsentPdfGenerator.new(@patient_consent).generate
    redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
                notice: 'PDFを生成しました。'
  rescue StandardError => e
    Rails.logger.error "PDF Generation Error: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
                alert: "PDF生成中にエラーが発生しました: #{e.message}"
  end

  # GET /medical_records/:medical_record_id/patient_consents/:id/download_pdf
  def download_pdf
    pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{@patient_consent.id}.pdf")

    # PDFファイルが存在しない場合はエラー
    unless File.exist?(pdf_path)
      redirect_to medical_record_patient_consent_path(@medical_record, @patient_consent),
                  alert: 'PDFが生成されていません。先にPDF生成を実行してください。'
      return
    end

    # PDFファイルを送信
    send_file pdf_path,
              type: 'application/pdf',
              disposition: 'attachment',
              filename: sanitize_filename("patient_consent_#{@patient_consent.id}.pdf")
  end

  # GET /medical_records/:medical_record_id/patient_consents/:id/preview_pdf
  def preview_pdf
    # PDF生成（一時ファイル）

    generator = PatientConsentPdfGenerator.new(@patient_consent)
    pdf_content = generator.generate_to_string

    send_data pdf_content,
              type: 'application/pdf',
              disposition: 'inline',
              filename: sanitize_filename("preview_patient_consent_#{@patient_consent.id}.pdf")
  rescue StandardError => e
    Rails.logger.error "PDF Preview Error: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render plain: "PDF生成中にエラーが発生しました: #{e.message}", status: :internal_server_error
  end

  # DELETE /medical_records/:medical_record_id/patient_consents/:id
  def destroy
    # 関連するPDFファイルを削除
    pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{@patient_consent.id}.pdf")
    FileUtils.rm_f(pdf_path)

    @patient_consent.destroy
    redirect_to medical_record_path(@medical_record), notice: '同意書を削除しました。'
  end

  private

  def set_patient_consent
    @patient_consent = @medical_record.patient_consents
                                      .includes(
                                        :patient,
                                        :consent_form_template,
                                        :facility_doctor,
                                        consent_item_responses: :consent_form_item
                                      )
                                      .find(params[:id])
  end

  def set_medical_record
    @medical_record = current_user.medical_records.find(params[:medical_record_id])
  end

  def set_patient_consents
    @patient_consents = @medical_record.patient_consents
  end

  def build_patient_consent(consent_params)
    # Strong Parametersで許可されたパラメータのみを取得
    permitted = permit_consent_params(consent_params)

    # テンプレート認可チェック（current_userが所有しているか確認）
    template = current_user.consent_form_templates.find(
      permitted[:consent_form_template_id]
    )

    # 医師認可チェック（施設所属確認）
    doctor = nil
    if permitted[:facility_doctor_id].present?
      doctor = @medical_record.facility.facility_doctors.find(
        permitted[:facility_doctor_id]
      )
    end

    patient_consent = @medical_record.patient_consents.build(
      patient: @medical_record.patient,
      user: current_user,
      consent_form_template: template,
      facility_doctor: doctor,
      signature_data: permitted[:signature_data]
    )

    # チェック項目の回答を作成
    if permitted[:consent_item_responses_attributes].present?
      permitted[:consent_item_responses_attributes].each_value do |response_params|
        patient_consent.consent_item_responses.build(
          consent_form_item_id: response_params[:consent_form_item_id],
          checked: response_params[:checked] == '1'
        )
      end
    end

    patient_consent
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "Authorization failed: #{e.message}"
    nil
  end

  # Strong Parameters: 許可するパラメータを定義
  def permit_consent_params(params)
    params.permit(
      :consent_form_template_id,
      :facility_doctor_id,
      :signature_data,
      consent_item_responses_attributes: %i[consent_form_item_id checked]
    )
  end

  # 同意書作成処理
  def process_consent_creation(errors)
    ActiveRecord::Base.transaction do
      @consents_data.each_value do |consent_params|
        next if consent_params[:selected] != '1'

        create_single_consent(consent_params, errors)
      end
    end
  end

  # 単一の同意書を作成
  def create_single_consent(consent_params, errors)
    patient_consent = build_patient_consent(consent_params)

    # 認可チェック失敗時（nilが返される）
    if patient_consent.nil?
      errors << '不正なテンプレートまたは医師が指定されました'
      raise ActiveRecord::Rollback
    end

    if patient_consent.save
      @created_consents << patient_consent
    else
      add_consent_error(patient_consent, errors)
      raise ActiveRecord::Rollback
    end
  end

  # 同意書保存失敗時のエラーメッセージを追加
  def add_consent_error(patient_consent, errors)
    title = patient_consent.consent_form_template.title
    error_messages = patient_consent.errors.full_messages.join(', ')
    errors << "#{title}: #{error_messages}"
  end

  # 作成結果の処理
  def handle_creation_result(errors)
    if errors.empty? && @created_consents.any?
      redirect_to medical_record_path(@medical_record),
                  notice: "#{@created_consents.count}件の同意書を作成しました。"
    else
      load_form_data
      flash.now[:alert] = errors.join("\n") if errors.any?
      render :new, status: :unprocessable_entity
    end
  end

  # フォームデータの読み込み
  def load_form_data
    @consent_form_templates = current_user.consent_form_templates
                                          .includes(:consent_form_items)
                                          .order(created_at: :desc)
    @facility_doctors = @medical_record.facility.facility_doctors.order(:name)
  end

  # ファイル名をサニタイズ（パストラバーサル対策）
  def sanitize_filename(filename)
    # 英数字、ハイフン、アンダースコア、ドット以外を除去
    filename.gsub(/[^\w\-.]/, '_')
  end
end
