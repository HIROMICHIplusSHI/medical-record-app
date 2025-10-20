class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Pundit未認可エラーハンドリング
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = 'この操作を実行する権限がありません。'
    redirect_to(request.referer || root_path)
  end
end
