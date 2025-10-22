class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, only: [:show]

  def index
    @inquiries = current_user.inquiries.recent.page(params[:page])
  end

  def show
    # 既読処理：管理者が最後に返信していたら、ユーザーが既読にする
    @inquiry.update(last_message_by: :user) if @inquiry.admin?

    @inquiry_messages = @inquiry.inquiry_messages.chronological
    @inquiry_message = @inquiry.inquiry_messages.build
  end

  def new
    @inquiry = current_user.inquiries.build
  end

  def create
    @inquiry = current_user.inquiries.build(inquiry_params.except(:body))

    ActiveRecord::Base.transaction do
      if @inquiry.save
        # 初回メッセージを作成
        @inquiry.inquiry_messages.create!(
          user: current_user,
          body: inquiry_params[:body]
        )

        redirect_to @inquiry, notice: 'お問い合わせを送信しました。'
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # ユーザーには一般的なメッセージを表示
    @inquiry.errors.add(:base, 'お問い合わせの送信に失敗しました。入力内容をご確認ください。')

    # 詳細はログに記録
    Rails.logger.error("Inquiry creation failed for user #{current_user.id}: #{e.message}")

    render :new, status: :unprocessable_entity
  end

  private

  def set_inquiry
    @inquiry = current_user.inquiries.find_by(id: params[:id])

    return if @inquiry

    redirect_to inquiries_path, alert: 'お問い合わせが見つかりません。'
  end

  def inquiry_params
    params.require(:inquiry).permit(:subject, :body, :category)
  end
end
