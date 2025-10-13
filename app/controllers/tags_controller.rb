class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: %i[edit update destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_tags

  def index
    @tags = current_user.tags.by_name
  end

  def new
    @tag = current_user.tags.build
  end

  def create
    @tag = current_user.tags.build(tag_params)

    if @tag.save
      respond_to_success
    else
      respond_to_failure
    end
  end

  def edit; end

  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: 'タグを更新しました。'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @tag.medical_records.exists?
      redirect_to tags_path, alert: "このタグは#{@tag.medical_records.count}件のカルテで使用中です。削除できません。"
    else
      @tag.destroy
      redirect_to tags_path, notice: 'タグを削除しました。'
    end
  end

  private

  def set_tag
    @tag = current_user.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :category, :color)
  end

  def redirect_to_tags
    redirect_to tags_path, alert: 'タグが見つかりません。'
  end

  def respond_to_success
    respond_to do |format|
      format.html { redirect_to tags_path, notice: 'タグを作成しました。' }
      format.json { render json: tag_json, status: :created }
    end
  end

  def respond_to_failure
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def tag_json
    { id: @tag.id, name: @tag.name, color: @tag.color }
  end
end
