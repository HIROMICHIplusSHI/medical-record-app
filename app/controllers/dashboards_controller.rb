class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date_range, only: %i[index export]

  def index
    # 年指定があれば月次データ、なければ現在の期間データ
    if params[:year].present?
      @year = params[:year].to_i
      @monthly_data = MedicalRecord.by_user(current_user.id).monthly_revenue(@year)
    else
      @monthly_data = MedicalRecord.by_user(current_user.id).monthly_revenue(Date.current.year)
    end

    # 期間内の総売上
    @total_revenue = MedicalRecord
                     .by_user(current_user.id)
                     .total_revenue(@start_date, @end_date)

    # 施設別売上
    @facility_data = MedicalRecord
                     .by_user(current_user.id)
                     .revenue_by_facility(@start_date, @end_date)
  end

  def export
    @facility_data = MedicalRecord
                     .by_user(current_user.id)
                     .revenue_by_facility(@start_date, @end_date)

    respond_to do |format|
      format.csv do
        send_data generate_csv(@facility_data),
                  filename: "revenue_report_#{@start_date}_#{@end_date}.csv",
                  type: 'text/csv; charset=utf-8'
      end
    end
  end

  private

  def set_date_range
    if params[:start_date].present? && params[:end_date].present?
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])

      if @start_date > @end_date
        flash[:alert] = '開始日は終了日より前である必要があります'
        @start_date = Date.current.beginning_of_month
        @end_date = Date.current.end_of_month
      end
    else
      # デフォルトは今月
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
    end
  rescue ArgumentError
    flash[:alert] = '不正な日付形式です'
    @start_date = Date.current.beginning_of_month
    @end_date = Date.current.end_of_month
  end

  def generate_csv(facility_data)
    require 'csv'

    CSV.generate(headers: true, encoding: Encoding::UTF_8) do |csv|
      csv << %w[施設名 売上金額]

      facility_data.each do |data|
        csv << [data.name, data.revenue]
      end
    end
  end
end
