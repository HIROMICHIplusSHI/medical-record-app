class QuestionnairesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient
  before_action :set_questionnaire, only: %i[show edit update destroy]

  # フィーチャーフラグ: Phase 4-02で有効化
  USE_CHECKBOX_UI = true

  def new
    # 施術記録からの遷移の場合、セッションに保存
    store_return_medical_record_id

    # 予約時に入力された患者情報を事前入力（編集可能）
    @questionnaire = @patient.build_questionnaire(
      full_name: @patient.name,
      birth_date: @patient.date_of_birth,
      gender: @patient.gender,
      phone: @patient.phone
    )
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
      sync_to_patient
      redirect_to @patient, notice: '問診票が正常に登録されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # 施術記録からの遷移の場合、セッションに保存
    store_return_medical_record_id

    redirect_to new_patient_questionnaire_path(@patient), alert: '問診票が見つかりません。' unless @questionnaire
  end

  def edit
    redirect_to new_patient_questionnaire_path(@patient), alert: '問診票が見つかりません。' unless @questionnaire
    @use_checkbox_ui = USE_CHECKBOX_UI
    prepare_questionnaire_data if @questionnaire && @use_checkbox_ui
  end

  def update
    if @questionnaire.update(questionnaire_params)
      sync_to_patient
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
      :other_concerns,
      # 看護師確認
      :nurse_confirmed
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

    # テキスト入力フィールドも空文字で初期化
    @other_medical_condition_value = ''
    @drug_allergy_detail_value = ''
    @food_allergy_detail_value = ''
    @other_allergy_value = ''
    @supplement_detail_value = ''
    @other_medication_value = ''
    @surgery_details_value = ''
    @other_treatment_value = ''
    @past_treatment_date_value = ''
    @past_treatment_location_value = ''
    @trouble_detail_value = ''
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

    # テキスト入力フィールドの事前入力用データを抽出
    extract_text_field_values
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

  # JSON配列からテキスト入力フィールドの値を抽出
  def extract_text_field_values
    # 既往歴の「その他」詳細
    @other_medical_condition_value = extract_detail_value(@medical_conditions_array, 'その他')

    # アレルギー詳細
    @drug_allergy_detail_value = extract_detail_value(@allergies_array, '薬物')
    @food_allergy_detail_value = extract_detail_value(@allergies_array, '食物')
    @other_allergy_value = extract_detail_value(@allergies_array, 'その他')

    # 服薬詳細
    @supplement_detail_value = extract_detail_value(@current_medications_array, 'サプリメント')
    @other_medication_value = extract_detail_value(@current_medications_array, 'その他')

    # 手術歴（配列の最初の要素がテキスト）
    @surgery_details_value = @past_surgeries_array.first || ''

    # 希望施術の「その他」詳細
    @other_treatment_value = extract_detail_value(@desired_treatments_array, 'その他')

    # 過去のアートメイク経験詳細
    @past_treatment_date_value = extract_detail_value(@past_treatments_array, '施術時期')
    @past_treatment_location_value = extract_detail_value(@past_treatments_array, '施術場所')
    @trouble_detail_value = extract_detail_value(@past_treatments_array, 'トラブル')
  end

  # 配列から「キー: 値」形式の文字列を見つけて、値部分を抽出
  def extract_detail_value(array, key)
    return '' if array.blank?

    matching = array.find { |item| item.to_s.start_with?("#{key}:") || item.to_s.start_with?("#{key}：") }
    return '' unless matching

    # "キー: 値" または "キー：値" の形式から値部分を抽出
    matching.to_s.sub(/^#{Regexp.escape(key)}[:：]\s*/, '')
  end

  # 問診票の基本情報を患者レコードに同期
  # nilの値は同期しない（予約時の情報を保持）
  # バリデーションを実行して不正データの保存を防止
  def sync_to_patient
    sync_attributes = {}
    sync_attributes[:name] = @questionnaire.full_name if @questionnaire.full_name.present?
    sync_attributes[:date_of_birth] = @questionnaire.birth_date if @questionnaire.birth_date.present?
    sync_attributes[:gender] = @questionnaire.gender if @questionnaire.gender.present?
    sync_attributes[:phone] = @questionnaire.phone if @questionnaire.phone.present?

    @patient.assign_attributes(sync_attributes)
    if @patient.valid?
      @patient.save(touch: true)
    else
      Rails.logger.warn("Patient sync validation failed: #{@patient.errors.full_messages}")
    end
  end

  # 施術記録からの遷移の場合、セッションに保存
  def store_return_medical_record_id
    return unless params[:from_medical_record_id].present?

    medical_record_id = params[:from_medical_record_id].to_i
    # セキュリティチェック: 現在のユーザーの施術記録かどうか確認
    medical_record = current_user.medical_records.find_by(id: medical_record_id)
    session[:return_to_medical_record_id] = medical_record.id if medical_record
  end
end
