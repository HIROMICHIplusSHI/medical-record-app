module Admin
  class InquiriesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_inquiry, only: %i[show update]

    def index
      @inquiries = Inquiry.includes(:user).recent
      @inquiries = @inquiries.by_status(params[:status]) if valid_status?
      @inquiries = @inquiries.by_category(params[:category]) if valid_category?
      @inquiries = @inquiries.page(params[:page])
    end

    def show
      # 管理者が既読にする
      @inquiry.update(admin_read_at: Time.current)

      # 未対応の場合は対応中に変更
      @inquiry.update(status: :in_progress) if @inquiry.open?

      @inquiry_messages = @inquiry.inquiry_messages.chronological
      @inquiry_message = @inquiry.inquiry_messages.build
    end

    def update
      if @inquiry.update(inquiry_params)
        redirect_to admin_inquiry_path(@inquiry), notice: 'ステータスを更新しました。'
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_inquiry
      @inquiry = Inquiry.find(params[:id])
    end

    def inquiry_params
      params.require(:inquiry).permit(:status)
    end

    def require_admin!
      return if current_user&.admin?

      redirect_to user_dashboard_path, alert: '管理者権限が必要です。'
    end

    def valid_status?
      params[:status].present? && Inquiry.statuses.key?(params[:status])
    end

    def valid_category?
      params[:category].present? && Inquiry.categories.key?(params[:category])
    end
  end
end
