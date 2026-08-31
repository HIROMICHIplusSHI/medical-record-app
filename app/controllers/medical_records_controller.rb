class MedicalRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record, only: %i[show edit update destroy remove_photo]
  before_action :set_patient_scope, only: %i[index new]

  def index
    records = current_user.medical_records.includes(:patient, :facility, :tags)
    # 患者ネスト（/patients/:patient_id/medical_records）の場合はその患者に限定する
    records = records.where(patient_id: @patient.id) if @patient

    @q = records.ransack(params[:q])
    # 「施術履歴」は時系列が意味を持つため、指定が無ければ来院日の新しい順にする
    @q.sorts = 'visit_date desc' if @q.sorts.empty?
    @medical_records = @q.result
                         .page(params[:page])
                         .per(20)
  end

  def show; end

  def new
    @medical_record = current_user.medical_records.build(patient: @patient)
    load_form_data
  end

  def create
    @medical_record = current_user.medical_records.build(medical_record_params)
    if @medical_record.save
      redirect_to @medical_record, notice: '施術記録を作成しました。'
    else
      # 患者起点で作成していた場合は、再描画でも患者の文脈（パンくず・戻り先）を保つ
      @patient = current_user.patients.find_by(id: medical_record_params[:patient_id])
      load_form_data
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_form_data
  end

  def update
    if @medical_record.update(medical_record_params)
      redirect_to @medical_record, notice: '施術記録を更新しました。'
    else
      load_form_data
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @medical_record.destroy
    redirect_to medical_records_path, notice: '施術記録を削除しました。'
  end

  def remove_photo
    attachment = @medical_record.photos.attachments.find_by(id: params[:photo_id])
    if attachment
      attachment.purge
      redirect_to edit_medical_record_path(@medical_record), notice: '画像を削除しました。'
    else
      redirect_to edit_medical_record_path(@medical_record), alert: '画像が見つかりません。'
    end
  end

  private

  # 患者ネストのルートで渡された patient_id を current_user の患者に限定して解決する。
  # 他ユーザーの患者 ID を渡された場合は RecordNotFound となり 404 を返す。
  def set_patient_scope
    return if params[:patient_id].blank?

    @patient = current_user.patients.find(params[:patient_id])
  end

  def set_medical_record
    @medical_record = current_user.medical_records
                                  .includes(
                                    :patient,
                                    :facility,
                                    :tags,
                                    cost_items: :cost_sheet,
                                    patient_consents: [
                                      :consent_form_template,
                                      :facility_doctor,
                                      { consent_item_responses: :consent_form_item },
                                    ]
                                  )
                                  .find(params[:id])
  end

  def medical_record_params
    params.require(:medical_record).permit(
      :patient_id,
      :facility_id,
      :visit_date,
      :treatment_location,
      :chief_complaint,
      :diagnosis,
      :treatment_content,
      :notes,
      photos: [],
      tag_ids: [],
      cost_items_attributes: %i[id cost_sheet_id item_name quantity unit_price _destroy]
    )
  end

  def load_form_data
    @patients = current_user.patients.order(:name)
    @facilities = current_user.facilities.by_name
    @cost_sheets = current_user.cost_sheets.by_name
    @tags = current_user.tags.by_name
  end
end
