class InquiryMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry

  def create
    @inquiry_message = @inquiry.inquiry_messages.build(inquiry_message_params)
    @inquiry_message.user = current_user

    if @inquiry_message.save
      redirect_to @inquiry, notice: 'メッセージを送信しました。'
    else
      @inquiry_messages = @inquiry.inquiry_messages.chronological
      render 'inquiries/show', status: :unprocessable_entity
    end
  end

  private

  def set_inquiry
    @inquiry = current_user.inquiries.find_by(id: params[:inquiry_id])

    return if @inquiry

    redirect_to inquiries_path, alert: 'お問い合わせが見つかりません。'
  end

  def inquiry_message_params
    params.require(:inquiry_message).permit(:body)
  end
end
