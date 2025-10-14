class QuestionnairesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient
  before_action :set_questionnaire, only: %i[edit update destroy]

  # フィーチャーフラグ: Phase 4-02で有効化
  USE_CHECKBOX_UI = true

  def new
    @questionnaire = @patient.build_questionnaire
    @use_checkbox_ui = USE_CHECKBOX_UI
    initialize_empty_arrays if @use_checkbox_ui
  end

  def create
    # 既に問診票が存在する場合は編集ページにリダイレクト
    if @patient.questionnaire.present?
      redirect_to edit_patient_questionnaire_path(@patient), alert: '問診票は既に存在します。編集してください。'
      return
    end

    @questionnaire = @patient.build_questionnaire(questionnaire_params)

    if @questionnaire.save
      redirect_to @patient, notice: '問診票が正常に登録されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to new_patient_questionnaire_path(@patient), alert: '問診票が見つかりません。' unless @questionnaire
    @use_checkbox_ui = USE_CHECKBOX_UI
    prepare_questionnaire_data if @questionnaire && @use_checkbox_ui
  end

  def update
    if @questionnaire.update(questionnaire_params)
      redirect_to @patient, notice: '問診票が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @questionnaire.destroy
    redirect_to @patient, notice: '問診票が正常に削除されました。'
  end

  private

  def set_patient
    @patient = current_user.patients.find_by(id: params[:patient_id])
    return if @patient

    redirect_to patients_path, alert: 'アクセス権限がありません。'
  end

  def set_questionnaire
    @questionnaire = @patient.questionnaire if @patient
  end

  def questionnaire_params
    params.require(:questionnaire).permit(
      # 基本情報
      :full_name,
      :full_name_kana,
      :birth_date,
      :gender,
      :phone,
      :email,
      :postal_code,
      :address,
      :emergency_contact,
      # 医療情報（JSON形式）
      :medical_conditions,
      :allergies,
      :current_medications,
      :past_surgeries,
      :pregnancy_info,
      # 施術情報（JSON形式）
      :desired_treatments,
      :past_treatments,
      :skin_conditions,
      :other_concerns
    )
  end

  def initialize_empty_arrays
    # 新規作成時は空配列で初期化
    @medical_conditions_array = []
    @allergies_array = []
    @current_medications_array = []
    @past_surgeries_array = []
    @pregnancy_info_array = []
    @desired_treatments_array = []
    @past_treatments_array = []
    @skin_conditions_array = []
  end

  def prepare_questionnaire_data
    # JSONデータを配列に変換してインスタンス変数に格納
    fields = %i[
      medical_conditions allergies current_medications past_surgeries
      pregnancy_info desired_treatments past_treatments skin_conditions
    ]

    fields.each do |field|
      instance_variable_set("@#{field}_array", parse_json_field(@questionnaire.send(field)))
    end
  end

  def parse_json_field(field_value)
    return [] if field_value.blank?

    # 既に配列の場合
    return field_value if field_value.is_a?(Array)

    # JSON文字列の場合
    begin
      parsed = JSON.parse(field_value)
      parsed.is_a?(Array) ? parsed : []
    rescue JSON::ParserError
      []
    end
  end
end
