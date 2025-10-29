# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::InvitationCodes', type: :request do
  let(:admin) { create(:user, role: :admin, create_invitation_code: false) }
  let!(:test_invitation_code) { create(:invitation_code, created_by: admin, code: 'TESTCODE') }
  let(:user) { create(:user, invitation_code_input: test_invitation_code.code, create_invitation_code: false) }
  let(:invitation_code) { create(:invitation_code, created_by: admin) }

  describe 'GET /admin/invitation_codes' do
    context '管理者の場合' do
      before { sign_in admin }

      it '招待コード一覧が表示される' do
        create_list(:invitation_code, 3, created_by: admin)
        get admin_invitation_codes_path
        expect(response).to have_http_status(:success)
      end

      it '検索条件で絞り込める' do
        create(:invitation_code, created_by: admin, status: :active)
        create(:invitation_code, created_by: admin, status: :inactive)

        get admin_invitation_codes_path, params: { q: { status_eq: 'active' } }
        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_invitation_codes_path
        expect(response).to redirect_to(user_dashboard_path)
        follow_redirect!
        expect(response.body).to include('管理者権限が必要です')
      end
    end
  end

  describe 'GET /admin/invitation_codes/:id' do
    context '管理者の場合' do
      before { sign_in admin }

      it '招待コード詳細が表示される' do
        get admin_invitation_code_path(invitation_code)
        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_invitation_code_path(invitation_code)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'GET /admin/invitation_codes/new' do
    context '管理者の場合' do
      before { sign_in admin }

      it '招待コード作成フォームが表示される' do
        get new_admin_invitation_code_path
        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get new_admin_invitation_code_path
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'POST /admin/invitation_codes' do
    context '管理者の場合' do
      before { sign_in admin }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            invitation_code: {
              code: 'TESTCODE1',
              max_uses: 10,
              expires_at: 1.month.from_now,
            },
          }
        end

        it '招待コードが作成される' do
          expect do
            post admin_invitation_codes_path, params: valid_params
          end.to change(InvitationCode, :count).by(1)

          expect(response).to redirect_to(admin_invitation_codes_path)
          follow_redirect!
          expect(response.body).to include('招待コードを作成しました')
        end

        it '作成者が自動的に設定される' do
          post admin_invitation_codes_path, params: valid_params
          expect(InvitationCode.last.created_by).to eq(admin)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            invitation_code: {
              code: '', # 必須項目を空にする
              max_uses: 10,
            },
          }
        end

        it '招待コードが作成されない' do
          expect do
            post admin_invitation_codes_path, params: invalid_params
          end.not_to change(InvitationCode, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        post admin_invitation_codes_path, params: { invitation_code: { code: 'TEST' } }
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'GET /admin/invitation_codes/:id/edit' do
    context '管理者の場合' do
      before { sign_in admin }

      it '招待コード編集フォームが表示される' do
        get edit_admin_invitation_code_path(invitation_code)
        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get edit_admin_invitation_code_path(invitation_code)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'PATCH /admin/invitation_codes/:id' do
    context '管理者の場合' do
      before { sign_in admin }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            invitation_code: {
              max_uses: 20,
              expires_at: 2.months.from_now,
            },
          }
        end

        it '招待コードが更新される' do
          patch admin_invitation_code_path(invitation_code), params: valid_params

          expect(response).to redirect_to(admin_invitation_code_path(invitation_code))
          follow_redirect!
          expect(response.body).to include('招待コードを更新しました')

          invitation_code.reload
          expect(invitation_code.max_uses).to eq(20)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            invitation_code: {
              max_uses: -1, # 無効な値
            },
          }
        end

        it '招待コードが更新されない' do
          original_max_uses = invitation_code.max_uses
          patch admin_invitation_code_path(invitation_code), params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)

          invitation_code.reload
          expect(invitation_code.max_uses).to eq(original_max_uses)
        end
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        patch admin_invitation_code_path(invitation_code),
              params: { invitation_code: { max_uses: 20 } }
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'DELETE /admin/invitation_codes/:id' do
    context '管理者の場合' do
      before { sign_in admin }

      it '招待コードが削除される' do
        code_to_delete = create(:invitation_code, created_by: admin)

        expect do
          delete admin_invitation_code_path(code_to_delete)
        end.to change(InvitationCode, :count).by(-1)

        expect(response).to redirect_to(admin_invitation_codes_path)
        follow_redirect!
        expect(response.body).to include('招待コードを削除しました')
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        delete admin_invitation_code_path(invitation_code)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'GET /admin/invitation_codes/export' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'CSVファイルがダウンロードされる' do
        create_list(:invitation_code, 3, created_by: admin)

        get export_admin_invitation_codes_path(format: :csv)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('invitation_codes')
      end

      it 'CSVに正しいデータが含まれる' do
        create(:invitation_code, created_by: admin, code: 'CODE001')
        create(:invitation_code, created_by: admin, code: 'CODE002')

        get export_admin_invitation_codes_path(format: :csv)

        csv_content = response.body
        expect(csv_content).to include('CODE001')
        expect(csv_content).to include('CODE002')
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get export_admin_invitation_codes_path(format: :csv)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'PATCH /admin/invitation_codes/:id/suspend' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'アクティブな招待コードが停止される' do
        active_code = create(:invitation_code, created_by: admin, status: :active)

        patch suspend_admin_invitation_code_path(active_code)

        expect(response).to redirect_to(admin_invitation_code_path(active_code))
        follow_redirect!
        expect(response.body).to include('招待コードを停止しました')

        active_code.reload
        expect(active_code.status).to eq('inactive')
      end

      it 'すでに停止中の招待コードの場合はエラーになる' do
        inactive_code = create(:invitation_code, created_by: admin, status: :inactive)

        patch suspend_admin_invitation_code_path(inactive_code)

        expect(response).to redirect_to(admin_invitation_code_path(inactive_code))
        follow_redirect!
        expect(response.body).to include('この招待コードは既に停止されています')
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        patch suspend_admin_invitation_code_path(invitation_code)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'PATCH /admin/invitation_codes/:id/activate' do
    context '管理者の場合' do
      before { sign_in admin }

      it '停止中の招待コードがアクティブになる' do
        inactive_code = create(:invitation_code, created_by: admin, status: :inactive)

        patch activate_admin_invitation_code_path(inactive_code)

        expect(response).to redirect_to(admin_invitation_code_path(inactive_code))
        follow_redirect!
        expect(response.body).to include('招待コードを有効化しました')

        inactive_code.reload
        expect(inactive_code.status).to eq('active')
      end

      it 'すでにアクティブな招待コードの場合はエラーになる' do
        active_code = create(:invitation_code, created_by: admin, status: :active)

        patch activate_admin_invitation_code_path(active_code)

        expect(response).to redirect_to(admin_invitation_code_path(active_code))
        follow_redirect!
        expect(response.body).to include('この招待コードは既に有効です')
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        patch activate_admin_invitation_code_path(invitation_code)
        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end
end
