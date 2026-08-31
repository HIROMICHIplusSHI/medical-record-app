class PatientsController < ApplicationController
  # 患者詳細に並べる施術履歴の表示件数（超過分は施術履歴一覧へ誘導する）
  RECENT_MEDICAL_RECORDS_LIMIT = 5

  before_action :authenticate_user!
  before_action :set_patient, only: %i[show edit update destroy]

  def index
    @patients = current_user.patients.recent
    @patients = @patients.search(params[:query]) if params[:query].present?
    @patients = Kaminari.paginate_array(@patients).page(params[:page]).per(25)
  end

  def show
    # 患者だけでなく施術記録側も current_user 起点にする。
    # patient 経由だけだと、他ユーザーが作成した記録まで拾ってしまう。
    records = current_user.medical_records.where(patient_id: @patient.id)
    @recent_medical_records = records.includes(:facility, :tags)
                                     .recent
                                     .limit(RECENT_MEDICAL_RECORDS_LIMIT)
    @medical_records_count = records.count
  end

  def new
    @patient = current_user.patients.build
  end

  def create
    @patient = current_user.patients.build(patient_params)

    if @patient.save
      redirect_to @patient, notice: '患者が正常に登録されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @patient.update(patient_params)
      redirect_to @patient, notice: '患者情報が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @patient.destroy
    redirect_to patients_url, notice: '患者が正常に削除されました。'
  end

  private

  def set_patient
    @patient = current_user.patients.includes(:questionnaire).find_by(id: params[:id])

    return if @patient

    redirect_to patients_path, alert: 'アクセス権限がありません。'
  end

  def patient_params
    params.require(:patient).permit(:name, :date_of_birth, :gender, :phone, :email, :address, :emergency_contact)
  end
end
