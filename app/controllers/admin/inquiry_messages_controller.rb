module Admin
  class InquiryMessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_inquiry

    def create
      @inquiry_message = @inquiry.inquiry_messages.build(inquiry_message_params)
      @inquiry_message.user = current_user

      if @inquiry_message.save
        redirect_to admin_inquiry_path(@inquiry), notice: '返信しました。'
      else
        @inquiry_messages = @inquiry.inquiry_messages.chronological
        render 'admin/inquiries/show', status: :unprocessable_entity
      end
    end

    private

    def set_inquiry
      @inquiry = Inquiry.find(params[:inquiry_id])
    end

    def inquiry_message_params
      params.require(:inquiry_message).permit(:body)
    end

    def require_admin!
      return if current_user&.admin?

      redirect_to user_dashboard_path, alert: '管理者権限が必要です。'
    end
  end
end
