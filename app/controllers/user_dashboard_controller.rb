class HomeController < ApplicationController
  before_action :authenticate_user!

  # セッションに保存する非表示お知らせIDの最大数
  MAX_DISMISSED_ANNOUNCEMENTS = 100

  def index
    @announcements = Announcement.active
  end

  def dismiss_announcement
    # Strong Parameters
    announcement_id = dismiss_params[:announcement_id].to_i

    # バリデーション: お知らせの存在確認
    announcement = Announcement.find_by(id: announcement_id)
    return head :not_found unless announcement
    return head :forbidden unless announcement.active?

    # セッション管理: サイズ制限付き
    session[:dismissed_announcements] ||= []

    # サイズ制限: 最大数を超えた場合は古いものから削除
    session[:dismissed_announcements].shift if session[:dismissed_announcements].size >= MAX_DISMISSED_ANNOUNCEMENTS

    # 重複防止
    unless session[:dismissed_announcements].include?(announcement_id)
      session[:dismissed_announcements] << announcement_id
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error("Failed to dismiss announcement: #{e.message}")
    head :internal_server_error
  end

  private

  def dismiss_params
    params.permit(:announcement_id)
  end
end
