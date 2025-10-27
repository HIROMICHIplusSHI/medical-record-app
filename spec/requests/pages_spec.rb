require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  let(:user) { create(:user) }
  let(:user_without_acceptance) do
    # 既存ユーザーという設定なので、作成後にタイムスタンプをnilに更新
    user = create(:user)
    user.update_columns(terms_accepted_at: nil, privacy_accepted_at: nil)
    user
  end

  describe 'GET /terms' do
    it '利用規約ページが表示される' do
      get terms_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('電子カルテシステム利用規約')
    end

    it '未認証でもアクセスできる' do
      get terms_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /privacy' do
    it 'プライバシーポリシーページが表示される' do
      get privacy_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('プライバシーポリシー')
    end

    it '未認証でもアクセスできる' do
      get privacy_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /accept_terms' do
    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get accept_terms_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みで規約未同意の場合' do
      before { sign_in user_without_acceptance }

      it '規約同意確認ページが表示される' do
        get accept_terms_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('利用規約への同意')
      end
    end

    context '認証済みで規約同意済みの場合' do
      before { sign_in user }

      it 'ダッシュボードにリダイレクトされる' do
        get accept_terms_path

        expect(response).to redirect_to(user_dashboard_path)
      end
    end
  end

  describe 'PATCH /accept_terms' do
    before { sign_in user_without_acceptance }

    context '両方のチェックボックスがチェックされている場合' do
      it '規約同意が更新される' do
        expect do
          patch accept_terms_path, params: { terms_accepted: 'true', privacy_accepted: 'true' }
          user_without_acceptance.reload
        end.to change { user_without_acceptance.terms_accepted_at }.from(nil)
                                                                   .and change {
                                                                          user_without_acceptance.privacy_accepted_at
                                                                        }.from(nil)

        expect(response).to redirect_to(user_dashboard_path)
        expect(flash[:notice]).to eq('利用規約とプライバシーポリシーに同意いただきありがとうございます。')
      end
    end

    context '利用規約のみチェックされている場合' do
      it '規約同意確認ページが再表示される' do
        patch accept_terms_path, params: { terms_accepted: 'true', privacy_accepted: 'false' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('利用規約への同意')
        expect(flash[:alert]).to eq('利用規約とプライバシーポリシーへの同意が必要です。')
      end
    end

    context 'プライバシーポリシーのみチェックされている場合' do
      it '規約同意確認ページが再表示される' do
        patch accept_terms_path, params: { terms_accepted: 'false', privacy_accepted: 'true' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('利用規約への同意')
        expect(flash[:alert]).to eq('利用規約とプライバシーポリシーへの同意が必要です。')
      end
    end

    context '両方チェックされていない場合' do
      it '規約同意確認ページが再表示される' do
        patch accept_terms_path, params: { terms_accepted: 'false', privacy_accepted: 'false' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('利用規約への同意')
        expect(flash[:alert]).to eq('利用規約とプライバシーポリシーへの同意が必要です。')
      end
    end
  end
end
