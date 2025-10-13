class CostSheetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cost_sheet, only: %i[edit update destroy]

  def index
    @cost_sheets = current_user.cost_sheets.by_name
  end

  def new
    @cost_sheet = current_user.cost_sheets.build
  end

  def create
    @cost_sheet = current_user.cost_sheets.build(cost_sheet_params)
    if @cost_sheet.save
      redirect_to cost_sheets_path, notice: 'コストシートを作成しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @cost_sheet.update(cost_sheet_params)
      redirect_to cost_sheets_path, notice: 'コストシートを更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cost_sheet.destroy
    redirect_to cost_sheets_path, notice: 'コストシートを削除しました。'
  end

  private

  def set_cost_sheet
    @cost_sheet = current_user.cost_sheets.find(params[:id])
  end

  def cost_sheet_params
    params.require(:cost_sheet).permit(:item_name, :standard_price, :category, :memo)
  end
end
