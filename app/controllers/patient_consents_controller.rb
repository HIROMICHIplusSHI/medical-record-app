class PatientConsentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record
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

  private

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
end
