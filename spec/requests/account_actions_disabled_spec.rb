# frozen_string_literal: true

require 'rails_helper'

# ポートフォリオ公開用のデモ環境として、アカウント操作系の導線を無効化している（Issue #64）。
# 訪問者にはデモログインだけを使ってもらう方針。
#
# 杭（実装開始後は変更不可）:
# 1. 無効化した画面は URL 直打ちでも実行されない（500 や実処理に到達しない）
# 2. 無効化しても既存ユーザーのログイン・ログアウトは従来どおり動く
# 3. デモアカウントのメールアドレス・パスワードは変更できない（変更されるとデモが壊れるため）
RSpec.describe 'アカウント操作の無効化', type: :request do
  describe '新規登録' do
    it '【杭1】申請画面はログイン画面へリダイレクトされること' do
      get new_user_registration_path

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to include('デモ')
    end

    it '【杭1】POST してもユーザーが作成されないこと' do
      expect do
        post user_registration_path, params: {
          user: {
            email: 'intruder@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            terms_accepted: 'true',
            privacy_accepted: 'true',
          },
        }
      end.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'パスワード再設定' do
    let!(:user) { create(:user, email: 'forgot@example.com') }

    it '【杭1】申請画面はログイン画面へリダイレクトされること' do
      get new_user_password_path

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to include('デモ')
    end

    it '【杭1】POST しても再設定メールが送信されないこと' do
      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it '【杭1】トークン付きの再設定フォームも開けないこと' do
      get edit_user_password_path(reset_password_token: 'dummy-token')

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'アカウント編集' do
    let(:user) { create(:user, email: 'demo@example.com') }

    before { sign_in user }

    it '【杭1】編集画面はダッシュボードへリダイレクトされること' do
      get edit_user_registration_path

      expect(response).to redirect_to(user_dashboard_path)
      expect(flash[:notice]).to include('デモ')
    end

    it '【杭3】メールアドレスを変更できないこと' do
      expect do
        put user_registration_path, params: {
          user: { email: 'hijacked@example.com', current_password: 'password123' },
        }
        user.reload
      end.not_to change(user, :email)
    end

    it '【杭1】アカウントを削除できないこと' do
      user

      expect { delete user_registration_path }.not_to change(User, :count)
    end
  end

  describe '【杭2】既存の認証導線' do
    let!(:user) { create(:user, email: 'active@example.com', password: 'password123') }

    it 'ログイン画面は従来どおり表示されること' do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end

    it 'ログインできること' do
      post user_session_path, params: { user: { email: user.email, password: 'password123' } }

      expect(response).to redirect_to(user_dashboard_path)
    end

    it 'ログアウトできること' do
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
    end
  end
end
