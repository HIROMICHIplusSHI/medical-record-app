class ConsentFormTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_consent_form_template, only: %i[show edit update destroy sort_items]

  def index
    @consent_form_templates = current_user.consent_form_templates.recent
  end

  def show; end

  def new
    @consent_form_template = current_user.consent_form_templates.build
  end

  def create
    @consent_form_template = current_user.consent_form_templates.build(consent_form_template_params)

    if @consent_form_template.save
      redirect_to @consent_form_template, notice: '同意書テンプレートが正常に作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @consent_form_template.update(consent_form_template_params)
      redirect_to @consent_form_template, notice: '同意書テンプレートが正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @consent_form_template.destroy
    redirect_to consent_form_templates_url, notice: '同意書テンプレートが正常に削除されました。'
  end

  def sort_items
    items = params[:items]

    ActiveRecord::Base.transaction do
      items.each do |item_data|
        item = @consent_form_template.consent_form_items.find(item_data[:id])
        item.update!(position: item_data[:position])
      end
    end

    render json: { success: true, message: '並び順を更新しました' }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: e.message }, status: :not_found
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_consent_form_template
    @consent_form_template = current_user.consent_form_templates.find_by(id: params[:id])

    return if @consent_form_template

    redirect_to consent_form_templates_path, alert: 'アクセス権限がありません。'
  end

  def consent_form_template_params
    params.require(:consent_form_template).permit(
      :title, :description, :is_active,
      consent_form_items_attributes: %i[id content position is_required _destroy]
    )
  end
end
