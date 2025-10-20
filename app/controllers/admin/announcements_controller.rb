module Admin
  class AnnouncementsController < Admin::BaseController
    before_action :set_announcement, only: %i[show edit update destroy publish archive]

    def index
      @q = Announcement.ransack(params[:q])
      @announcements = @q.result
                         .includes(:author)
                         .order(created_at: :desc)
                         .page(params[:page])

      authorize Announcement
    end

    def show
      authorize @announcement
    end

    def new
      @announcement = Announcement.new
      authorize @announcement
    end

    def create
      @announcement = Announcement.new(announcement_params)
      @announcement.author = current_user

      authorize @announcement

      if @announcement.save
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを作成しました。'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @announcement
    end

    def update
      authorize @announcement

      if @announcement.update(announcement_params)
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcements_path, notice: 'お知らせをアーカイブしました。'
    end

    def publish
      authorize @announcement

      @announcement.published_at ||= Time.current
      @announcement.status = :published

      if @announcement.save
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを公開しました。'
      else
        redirect_to admin_announcement_path(@announcement), alert: 'お知らせの公開に失敗しました。'
      end
    end

    def archive
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcement_path(@announcement), notice: 'お知らせをアーカイブしました。'
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(
        :title,
        :body,
        :severity,
        :published_at,
        :expires_at,
        :display_order,
        :status
      )
    end
  end
end
