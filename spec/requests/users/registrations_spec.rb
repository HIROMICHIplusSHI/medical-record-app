# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let(:admin) { create(:user, :admin, create_invitation_code: false) }
  let!(:valid_code) { create(:invitation_code, created_by: admin, code: 'TESTCODE', status: :active) }

  describe 'POST /users' do
    let(:valid_attributes) do
      {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        terms_accepted: 'true',
        privacy_accepted: 'true',
        invitation_code_input: 'TESTCODE',
      }
    end

    context '正常系：有効な招待コードでの新規登録' do
      it 'ユーザーが作成される' do
        expect do
          post user_registration_path, params: { user: valid_attributes }
        end.to change(User, :count).by(1)
      end

      it '招待コードの使用回数がインクリメントされる' do
        expect do
          post user_registration_path, params: { user: valid_attributes }
        end.to change { valid_code.reload.used_count }.by(1)
      end

      it 'ユーザーに招待コードが紐づけられる' do
        post user_registration_path, params: { user: valid_attributes }
        user = User.find_by(email: 'newuser@example.com')
        expect(user.invitation_code).to eq(valid_code)
      end

      it 'ユーザーダッシュボードにリダイレクトされる' do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(user_dashboard_path)
      end
    end

    context '正常系：招待コードの正規化（大文字変換・空白除去）' do
      it '小文字の招待コードが大文字に正規化される' do
        attributes = valid_attributes.merge(invitation_code_input: 'testcode')
        post user_registration_path, params: { user: attributes }

        user = User.find_by(email: 'newuser@example.com')
        expect(user.invitation_code).to eq(valid_code)
      end

      it '前後の空白が除去される' do
        attributes = valid_attributes.merge(invitation_code_input: '  TESTCODE  ')
        post user_registration_path, params: { user: attributes }

        user = User.find_by(email: 'newuser@example.com')
        expect(user.invitation_code).to eq(valid_code)
      end

      it '小文字と空白が同時に正規化される' do
        attributes = valid_attributes.merge(invitation_code_input: '  testcode  ')
        post user_registration_path, params: { user: attributes }

        user = User.find_by(email: 'newuser@example.com')
        expect(user.invitation_code).to eq(valid_code)
      end
    end

    context '異常系：招待コード不正' do
      it '招待コードなしで登録失敗' do
        attributes = valid_attributes.except(:invitation_code_input)

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end

      it '存在しない招待コードで登録失敗' do
        attributes = valid_attributes.merge(invitation_code_input: 'INVALID99')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end

      it '無効（inactive）な招待コードで登録失敗' do
        create(:invitation_code, :inactive, created_by: admin, code: 'INACTIVE1')
        attributes = valid_attributes.merge(invitation_code_input: 'INACTIVE1')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end

      it '期限切れの招待コードで登録失敗' do
        create(:invitation_code, :expired, created_by: admin, code: 'EXPIRED99')
        attributes = valid_attributes.merge(invitation_code_input: 'EXPIRED99')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end

      it '使用回数上限に達した招待コードで登録失敗' do
        create(:invitation_code, :max_uses_reached, created_by: admin, code: 'MAXOUT123')
        attributes = valid_attributes.merge(invitation_code_input: 'MAXOUT123')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end
    end

    context '異常系：規約同意なし' do
      it '利用規約未同意で登録失敗' do
        attributes = valid_attributes.merge(terms_accepted: 'false')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end

      it 'プライバシーポリシー未同意で登録失敗' do
        attributes = valid_attributes.merge(privacy_accepted: 'false')

        expect do
          post user_registration_path, params: { user: attributes }
        end.not_to change(User, :count)
      end
    end
  end
end
