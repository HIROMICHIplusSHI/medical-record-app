# frozen_string_literal: true

# デモアカウントへのワンクリックログインを扱うコントローラー。
class DemoSessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    raise ActionController::RoutingError, 'Not Found' unless DemoSession.enabled?

    demo_user = DemoSession.user
    return redirect_to new_user_session_path, alert: 'デモアカウントが利用できません。' if demo_user.nil?

    sign_in(demo_user)
    redirect_to user_dashboard_path, notice: 'デモアカウントでログインしました。'
  end
end
