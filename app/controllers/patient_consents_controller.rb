class PatientConsentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record
  before_action :set_patient_consents, only: [:index]

  # GET /medical_records/:medical_record_id/patient_consents
  def index
    @patient_consents = @medical_record.patient_consents.includes(:consent_form_template, :facility_doctor).recent
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

    ActiveRecord::Base.transaction do
      @consents_data.each_value do |consent_params|
        next if consent_params[:selected] != '1'

        patient_consent = build_patient_consent(consent_params)

        if patient_consent.save
          @created_consents << patient_consent
        else
          title = patient_consent.consent_form_template.title
          error_messages = patient_consent.errors.full_messages.join(', ')
          errors << "#{title}: #{error_messages}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if errors.empty? && @created_consents.any?
      redirect_to medical_record_path(@medical_record),
                  notice: "#{@created_consents.count}件の同意書を作成しました。"
    else
      @consent_form_templates = current_user.consent_form_templates
                                            .includes(:consent_form_items)
                                            .order(created_at: :desc)
      @facility_doctors = @medical_record.facility.facility_doctors.order(:name)
      flash.now[:alert] = errors.join("\n") if errors.any?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_medical_record
    @medical_record = current_user.medical_records.find(params[:medical_record_id])
  end

  def set_patient_consents
    @patient_consents = @medical_record.patient_consents
  end

  def build_patient_consent(consent_params)
    patient_consent = @medical_record.patient_consents.build(
      patient: @medical_record.patient,
      user: current_user,
      consent_form_template_id: consent_params[:consent_form_template_id],
      facility_doctor_id: consent_params[:facility_doctor_id],
      signature_data: consent_params[:signature_data]
    )

    # チェック項目の回答を作成
    if consent_params[:consent_item_responses_attributes].present?
      consent_params[:consent_item_responses_attributes].each_value do |response_params|
        patient_consent.consent_item_responses.build(
          consent_form_item_id: response_params[:consent_form_item_id],
          checked: response_params[:checked] == '1'
        )
      end
    end

    patient_consent
  end
end
