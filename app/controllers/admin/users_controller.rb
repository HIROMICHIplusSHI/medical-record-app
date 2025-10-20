module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[show toggle_role]

    def index
      @q = User.ransack(params[:q])
      @users = @q.result
                 .order(created_at: :desc)
                 .page(params[:page])

      authorize User
    end

    def show
      authorize @user

      # ユーザーの統計情報
      @stats = {
        medical_records_count: @user.medical_records.count,
        patients_count: @user.patients.count,
        facilities_count: @user.facilities.count,
        invoices_count: @user.invoices.count,
      }
    end

    def toggle_role
      authorize @user

      # 管理者を降格させる場合、他に管理者がいないと降格できない（自分自身チェックより優先）
      if @user.admin? && User.admin.where.not(id: @user.id).none?
        redirect_to admin_user_path(@user), alert: '最後の管理者の権限は変更できません。'
        return
      end

      # 自分自身の権限変更を防止
      if @user == current_user
        redirect_to admin_user_path(@user), alert: '自分自身の権限は変更できません。'
        return
      end

      new_role = @user.admin? ? :user : :admin
      @user.allow_role_change!

      if @user.update(role: new_role)
        role_name = @user.admin? ? '管理者' : 'ユーザー'
        redirect_to admin_user_path(@user), notice: "ユーザーの権限を#{role_name}に変更しました。"
      else
        redirect_to admin_user_path(@user), alert: '権限の変更に失敗しました。'
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
