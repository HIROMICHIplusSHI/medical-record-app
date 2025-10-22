module Admin
  class InquiriesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_inquiry, only: %i[show update]

    def index
      @inquiries = Inquiry.recent.page(params[:page])

      # 有効なステータス値のみ受け付ける
      return unless params[:status].present? && Inquiry.statuses.key?(params[:status])

      @inquiries = @inquiries.by_status(params[:status])
    end

    def show
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

      redirect_to user_root_path, alert: '管理者権限が必要です。'
    end
  end
end
