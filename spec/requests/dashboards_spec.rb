require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:facility1) { create(:facility, user: user, name: '施設A') }
  let(:facility2) { create(:facility, user: user, name: '施設B') }

  before do
    sign_in user

    # 2024年1月のデータ
    create(:medical_record, user: user, patient: patient, facility: facility1,
                            visit_date: Date.new(2024, 1, 15)) do |record|
      create(:cost_item, medical_record: record, quantity: 1, unit_price: 50_000)
    end

    create(:medical_record, user: user, patient: patient, facility: facility1,
                            visit_date: Date.new(2024, 1, 20)) do |record|
      create(:cost_item, medical_record: record, quantity: 2, unit_price: 30_000)
    end

    # 2024年2月のデータ
    create(:medical_record, user: user, patient: patient, facility: facility2,
                            visit_date: Date.new(2024, 2, 10)) do |record|
      create(:cost_item, medical_record: record, quantity: 1, unit_price: 80_000)
    end

    # 2024年3月のデータ
    create(:medical_record, user: user, patient: patient, facility: facility1,
                            visit_date: Date.new(2024, 3, 5)) do |record|
      create(:cost_item, medical_record: record, quantity: 3, unit_price: 20_000)
    end
  end

  describe 'GET /dashboard' do
    context '未ログイン' do
      before { sign_out user }

      it 'ログインページにリダイレクトする' do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済み' do
      it 'ダッシュボードページが表示される' do
        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('売上ダッシュボード')
      end

      it '今年の売上データを取得する' do
        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('月次売上推移')
        # 1月から12月までの月が表示される
        (1..12).each do |month|
          expect(response.body).to include("#{month}月")
        end
      end

      it '施設別売上データを取得する' do
        get dashboard_path, params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('施設別売上')
        expect(response.body).to include('施設A')
        expect(response.body).to include('施設B')
      end

      it '期間指定で売上データを取得する' do
        get dashboard_path, params: { start_date: '2024-01-01', end_date: '2024-01-31' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('110,000')
      end

      it '期間が指定されない場合は今月のデータを取得する' do
        travel_to Date.new(2024, 1, 25) do
          get dashboard_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include('2024年01月01日')
          expect(response.body).to include('2024年01月31日')
        end
      end

      it 'year パラメータで年次データを取得する' do
        get dashboard_path, params: { year: 2024 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('月次売上推移')
      end
    end
  end

  describe 'GET /dashboard/export' do
    context '未ログイン' do
      before { sign_out user }

      it '401 Unauthorizedエラーが返る' do
        get export_dashboard_path(format: :csv)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'ログイン済み' do
      it 'CSV形式でダウンロードできる' do
        get export_dashboard_path(format: :csv), params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('text/csv; charset=utf-8')
        expect(response.headers['Content-Disposition']).to include('attachment')
      end

      it 'CSVに正しいヘッダーが含まれる' do
        get export_dashboard_path(format: :csv), params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        csv_content = response.body
        expect(csv_content).to include('施設名')
        expect(csv_content).to include('売上金額')
      end

      it 'CSVに施設別売上データが含まれる' do
        get export_dashboard_path(format: :csv), params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        csv_content = response.body
        expect(csv_content).to include('施設A')
        expect(csv_content).to include('施設B')
        expect(csv_content).to include('170000') # 施設Aの売上
        expect(csv_content).to include('80000')  # 施設Bの売上
      end

      it '期間指定がない場合は今月のデータを出力する' do
        travel_to Date.new(2024, 1, 25) do
          get export_dashboard_path(format: :csv)
          expect(response).to have_http_status(:success)
          csv_content = response.body
          expect(csv_content).to include('施設A')
        end
      end
    end
  end
end
