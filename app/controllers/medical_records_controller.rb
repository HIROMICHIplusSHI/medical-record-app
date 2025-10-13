class MedicalRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record, only: %i[show edit update destroy remove_photo]

  def index
    @q = current_user.medical_records
                     .includes(:patient, :facility, :tags)
                     .ransack(params[:q])
    @medical_records = @q.result
                         .page(params[:page])
                         .per(20)
  end

  def show; end

  def new
    @medical_record = current_user.medical_records.build
    load_form_data
  end

  def create
    @medical_record = current_user.medical_records.build(medical_record_params)
    if @medical_record.save
      redirect_to @medical_record, notice: 'カルテを作成しました。'
    else
      load_form_data
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_form_data
  end

  def update
    if @medical_record.update(medical_record_params)
      redirect_to @medical_record, notice: 'カルテを更新しました。'
    else
      load_form_data
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @medical_record.destroy
    redirect_to medical_records_path, notice: 'カルテを削除しました。'
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

  def set_medical_record
    @medical_record = current_user.medical_records
                                  .includes(:cost_items, :tags)
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
