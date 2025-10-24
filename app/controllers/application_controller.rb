class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  # Pundit未認可エラーハンドリング
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :show_footer?

  def show_footer?
    user_signed_in? || public_pages?
  end

  def public_pages?
    controller_name == 'pages' && %w[terms privacy].include?(action_name)
  end

  private

  def user_not_authorized
    flash[:alert] = 'この操作を実行する権限がありません。'
    fallback_path = current_user&.admin? ? admin_root_path : user_dashboard_path
    redirect_to(request.referer || fallback_path)
  end

  # ログイン後のリダイレクト先をロール別に設定
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path     # /admin
    else
      user_dashboard_path # /dashboard (ユーザーダッシュボード)
    end
  end

  # ログアウト後のリダイレクト先
  def after_sign_out_path_for(_resource_or_scope)
    root_path # ウェルカムページ
  end
end
