# frozen_string_literal: true

# ログイン後のユーザーダッシュボードコントローラー
class UserDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @announcements = Announcement.active
    @todays_medical_records = current_user.medical_records
                                          .includes(:patient, :facility)
                                          .where(visit_date: Date.current)
                                          .order(created_at: :desc)
  end
end
