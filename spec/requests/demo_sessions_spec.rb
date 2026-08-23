# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DemoSessions', type: :request do
  # 杭（実装開始後は変更不可）:
  # 1. デモログインは user ロールにのみサインインでき、admin には決してサインインできない
  # 2. デモ機能が無効な環境ではエンドポイントが機能しない（404）
  # 3. GET では発火しない（POST のみ）
  describe 'POST /demo_login' do
    context 'デモ機能が有効な場合' do
      before { allow(DemoSession).to receive(:enabled?).and_return(true) }

      context 'デモユーザーが存在する場合' do
        let!(:demo_user) do
          create(:user, email: DemoSession::DEMO_EMAIL, role: :user)
        end

        it 'デモユーザーとしてログインし、ダッシュボードへリダイレクトすること' do
          post demo_login_path

          expect(response).to redirect_to(user_dashboard_path)
          follow_redirect!
          expect(response.body).to include('デモ')
        end

        it 'ログイン後に認証必須ページへアクセスできること' do
          post demo_login_path
          get patients_path

          expect(response).to have_http_status(:ok)
        end

        it '【杭1】admin ロールのユーザーにはログインしないこと' do
          admin = create(:user, email: 'another-admin@example.com', role: :admin)

          post demo_login_path

          expect(controller.current_user).to eq(demo_user)
          expect(controller.current_user).not_to eq(admin)
          expect(controller.current_user).not_to be_admin
        end
      end

      context 'デモユーザーが admin ロールに変わっていた場合' do
        before { create(:user, email: DemoSession::DEMO_EMAIL, role: :admin) }

        it '【杭1】ログインさせずログイン画面へ戻すこと' do
          post demo_login_path

          expect(controller.current_user).to be_nil
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to be_present
        end
      end

      context 'デモユーザーが存在しない場合' do
        it 'ログイン画面へ戻し、エラーメッセージを表示すること' do
          post demo_login_path

          expect(controller.current_user).to be_nil
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to be_present
        end
      end
    end

    context '【杭2】デモ機能が無効な場合' do
      before { allow(DemoSession).to receive(:enabled?).and_return(false) }

      it 'デモユーザーが存在しても 404 を返しログインしないこと' do
        create(:user, email: DemoSession::DEMO_EMAIL, role: :user)

        post demo_login_path

        expect(response).to have_http_status(:not_found)
        expect(controller.current_user).to be_nil
      end
    end
  end

  describe '【杭3】GET /demo_login' do
    it 'GET ではルーティングされないこと（POST のみ受け付ける）' do
      routes = Rails.application.routes

      expect { routes.recognize_path('/demo_login', method: :get) }
        .to raise_error(ActionController::RoutingError)
      expect(routes.recognize_path('/demo_login', method: :post))
        .to include(controller: 'demo_sessions', action: 'create')
    end
  end

  describe 'ログイン画面の表示' do
    context 'デモ機能が有効な場合' do
      before { allow(DemoSession).to receive(:enabled?).and_return(true) }

      it 'デモログインボタンが表示されること' do
        get new_user_session_path

        expect(response.body).to include('デモアカウントでログイン')
      end
    end

    context 'デモ機能が無効な場合' do
      before { allow(DemoSession).to receive(:enabled?).and_return(false) }

      it 'デモログインボタンが表示されないこと' do
        get new_user_session_path

        expect(response.body).not_to include('デモアカウントでログイン')
      end
    end
  end
end
