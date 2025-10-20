class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @announcements = Announcement.active
  end

  def dismiss_announcement
    announcement_id = params[:announcement_id].to_i
    session[:dismissed_announcements] ||= []
    unless session[:dismissed_announcements].include?(announcement_id)
      session[:dismissed_announcements] << announcement_id
    end

    head :ok
  end
end
