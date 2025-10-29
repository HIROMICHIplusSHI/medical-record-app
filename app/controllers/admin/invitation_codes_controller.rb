# frozen_string_literal: true

module Admin
  class InvitationCodesController < Admin::BaseController
    before_action :set_invitation_code, only: %i[show edit update destroy suspend activate]

    def index
      @q = InvitationCode.ransack(params[:q])
      @invitation_codes = @q.result.includes(:created_by).order(created_at: :desc).page(params[:page])
      authorize InvitationCode
    end

    def show
      authorize @invitation_code
    end

    def new
      @invitation_code = InvitationCode.new
      authorize @invitation_code
    end

    def create
      @invitation_code = InvitationCode.new(invitation_code_params)
      @invitation_code.created_by = current_user
      authorize @invitation_code

      if @invitation_code.save
        redirect_to admin_invitation_codes_path, notice: '招待コードを作成しました。'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @invitation_code
    end

    def update
      authorize @invitation_code

      if @invitation_code.update(invitation_code_params)
        redirect_to admin_invitation_code_path(@invitation_code), notice: '招待コードを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @invitation_code

      @invitation_code.destroy!
      redirect_to admin_invitation_codes_path, notice: '招待コードを削除しました。'
    end

    def export
      authorize InvitationCode

      @invitation_codes = InvitationCode.includes(:created_by).order(created_at: :desc)

      respond_to do |format|
        format.csv do
          send_data generate_csv(@invitation_codes),
                    filename: "invitation_codes_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                    type: 'text/csv'
        end
      end
    end

    def suspend
      authorize @invitation_code

      if @invitation_code.inactive?
        redirect_to admin_invitation_code_path(@invitation_code),
                    alert: 'この招待コードは既に停止されています。'
      else
        @invitation_code.update!(status: :inactive)
        redirect_to admin_invitation_code_path(@invitation_code), notice: '招待コードを停止しました。'
      end
    end

    def activate
      authorize @invitation_code

      if @invitation_code.active?
        redirect_to admin_invitation_code_path(@invitation_code),
                    alert: 'この招待コードは既に有効です。'
      else
        @invitation_code.update!(status: :active)
        redirect_to admin_invitation_code_path(@invitation_code), notice: '招待コードを有効化しました。'
      end
    end

    private

    def set_invitation_code
      @invitation_code = InvitationCode.find(params[:id])
    end

    def invitation_code_params
      params.require(:invitation_code).permit(:code, :max_uses, :expires_at)
    end

    def generate_csv(invitation_codes)
      require 'csv'

      CSV.generate(headers: true) do |csv|
        csv << %w[コード ステータス 使用回数 最大使用回数 有効期限 作成者 作成日]

        invitation_codes.each do |code|
          csv << [
            code.code,
            I18n.t("activerecord.attributes.invitation_code.statuses.#{code.status}"),
            code.used_count,
            code.max_uses || '無制限',
            code.expires_at ? I18n.l(code.expires_at, format: :long) : '無期限',
            code.created_by&.email || 'N/A',
            I18n.l(code.created_at, format: :long),
          ]
        end
      end
    end
  end
end
