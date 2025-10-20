module Admin
  class DashboardController < Admin::BaseController
    def index
      # システム統計
      @total_users = User.count
      @total_medical_records = MedicalRecord.count
      @active_announcements = Announcement.active.count

      # 最近登録されたユーザー
      @recent_users = User.order(created_at: :desc).limit(5)

      # 最近公開されたお知らせ
      @recent_announcements = Announcement.where(status: :published)
                                          .order(published_at: :desc)
                                          .limit(5)
    end
  end
end
