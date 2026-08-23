# frozen_string_literal: true

require 'rails_helper'

# db/seeds.rb は本番ビルド（bin/render-build.sh）から実行されるが、
# CI では一度も実行されないため死角になりやすい（Issue #86）。
# ここでは公開デモの安全性に直結する不変条件だけを検証する。
RSpec.describe 'db/seeds.rb' do
  subject(:run_seeds) { load Rails.root.join('db/seeds.rb') }

  before { allow($stdout).to receive(:puts) }

  it '正常に実行できること' do
    expect { run_seeds }.not_to raise_error
  end

  it 'デモユーザーと管理者が作成されること' do
    run_seeds

    expect(User.find_by(email: DemoSession::DEMO_EMAIL)).to be_present
    expect(User.find_by(email: 'admin@example.com')).to be_admin
  end

  describe '資格情報の非掲示（Issue #64）' do
    it 'お知らせ本文にパスワードを掲示しないこと' do
      run_seeds

      expect(Announcement.pluck(:body).join).not_to include('パスワード:')
    end

    it '資格情報を掲示していた旧お知らせを削除すること' do
      admin = create(:user, email: 'existing-admin@example.com', role: :admin)
      Announcement.create!(
        title: 'デモアカウント情報',
        body: "メールアドレス: demo@example.com\nパスワード: password123",
        author: admin,
        status: :published,
        severity: :info,
        published_at: 1.day.ago
      )

      run_seeds

      expect(Announcement.find_by(title: 'デモアカウント情報')).to be_nil
    end
  end

  describe '本番環境での管理者パスワード' do
    it 'ADMIN_SEED_PASSWORD 未設定の本番では中断すること' do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ADMIN_SEED_PASSWORD').and_yield

      expect { run_seeds }.to raise_error(RuntimeError, /ADMIN_SEED_PASSWORD/)
    end
  end
end
