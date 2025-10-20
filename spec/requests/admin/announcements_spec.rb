require 'rails_helper'

RSpec.describe 'Admin::Announcements', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin/announcements' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'お知らせ一覧が表示される' do
        create_list(:announcement, 3, author: admin)

        get admin_announcements_path

        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_announcements_path
        expect(response).to redirect_to(user_root_path)
      end
    end
  end

  describe 'GET /admin/announcements/:id' do
    let(:announcement) { create(:announcement, author: admin) }

    before { sign_in admin }

    it 'お知らせ詳細が表示される' do
      get admin_announcement_path(announcement)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/announcements' do
    before { sign_in admin }

    it 'お知らせを作成できる' do
      announcement_params = attributes_for(:announcement)

      expect do
        post admin_announcements_path, params: { announcement: announcement_params }
      end.to change(Announcement, :count).by(1)

      expect(response).to redirect_to(admin_announcement_path(Announcement.last))
    end
  end

  describe 'PATCH /admin/announcements/:id' do
    let(:announcement) { create(:announcement, author: admin) }

    before { sign_in admin }

    it 'お知らせを更新できる' do
      patch admin_announcement_path(announcement), params: {
        announcement: { title: '更新されたタイトル' }
      }

      expect(announcement.reload.title).to eq('更新されたタイトル')
      expect(response).to redirect_to(admin_announcement_path(announcement))
    end
  end

  describe 'PATCH /admin/announcements/:id/publish' do
    let(:announcement) { create(:announcement, author: admin, status: :draft) }

    before { sign_in admin }

    it 'お知らせを公開できる' do
      patch publish_admin_announcement_path(announcement)

      expect(announcement.reload.published?).to be true
      expect(announcement.published_at).to be_present
      expect(response).to redirect_to(admin_announcement_path(announcement))
    end
  end

  describe 'PATCH /admin/announcements/:id/archive' do
    let(:announcement) { create(:announcement, :published, author: admin) }

    before { sign_in admin }

    it 'お知らせをアーカイブできる' do
      patch archive_admin_announcement_path(announcement)

      expect(announcement.reload.archived?).to be true
      expect(response).to redirect_to(admin_announcement_path(announcement))
    end
  end

  describe 'DELETE /admin/announcements/:id' do
    let(:announcement) { create(:announcement, author: admin) }

    before { sign_in admin }

    it 'お知らせをアーカイブする（削除はアーカイブ扱い）' do
      delete admin_announcement_path(announcement)

      expect(announcement.reload.archived?).to be true
      expect(response).to redirect_to(admin_announcements_path)
    end
  end
end
