class FacilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_facility, only: %i[show edit update destroy]

  def index
    @facilities = current_user.facilities.recent
  end

  def show; end

  def new
    @facility = current_user.facilities.build
  end

  def create
    @facility = current_user.facilities.build(facility_params)

    if @facility.save
      redirect_to @facility, notice: '施設が正常に作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @facility.update(facility_params)
      redirect_to @facility, notice: '施設が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @facility.destroy
    redirect_to facilities_url, notice: '施設が正常に削除されました。'
  end

  private

  def set_facility
    @facility = current_user.facilities.find_by(id: params[:id])

    return if @facility

    redirect_to facilities_path, alert: 'アクセス権限がありません。'
  end

  def facility_params
    params.require(:facility).permit(
      :name, :address, :phone, :email, :notes, :billing_addressee, :billing_rate,
      facility_doctors_attributes: %i[id name medical_license_number specialization _destroy]
    )
  end
end
