module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout 'admin'

    private

    def require_admin!
      return if current_user&.admin?

      flash[:alert] = '管理者権限が必要です。'
      redirect_to user_root_path
    end
  end
end
