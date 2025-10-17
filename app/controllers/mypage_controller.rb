class MypageController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to mypage_path, notice: '設定を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :company_name,
      :company_postal,
      :company_address,
      :company_phone,
      :company_email,
      :bank_info
    )
  end
end
