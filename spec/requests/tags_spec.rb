require 'rails_helper'

RSpec.describe 'Tags', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:tag) { create(:tag, user: user) }
  let(:valid_attributes) do
    {
      name: 'テストタグ',
      category: '施術',
      color: '#FF0000',
    }
  end
  let(:invalid_attributes) do
    {
      name: '',
      color: 'invalid',
    }
  end

  before do
    sign_in user
  end

  describe 'GET /tags' do
    it '正常にレスポンスを返す' do
      get tags_path
      expect(response).to have_http_status(:success)
    end

    it 'ユーザーのタグのみを表示する' do
      create(:tag, user: user, name: 'ユーザーのタグ')
      create(:tag, user: other_user, name: '他のユーザーのタグ')

      get tags_path
      expect(response.body).to include('ユーザーのタグ')
      expect(response.body).not_to include('他のユーザーのタグ')
    end
  end

  describe 'GET /tags/new' do
    it '正常にレスポンスを返す' do
      get new_tag_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /tags' do
    context '有効なパラメータの場合' do
      it '新しいタグを作成する' do
        expect do
          post tags_path, params: { tag: valid_attributes }
        end.to change(Tag, :count).by(1)
      end

      it 'タグ一覧にリダイレクトする' do
        post tags_path, params: { tag: valid_attributes }
        expect(response).to redirect_to(tags_path)
      end

      it '成功メッセージを表示する' do
        post tags_path, params: { tag: valid_attributes }
        follow_redirect!
        expect(response.body).to include('タグを作成しました')
      end
    end

    context '無効なパラメータの場合' do
      it 'タグを作成しない' do
        expect do
          post tags_path, params: { tag: invalid_attributes }
        end.not_to change(Tag, :count)
      end

      it 'newテンプレートを再表示する' do
        post tags_path, params: { tag: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /tags/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_tag_path(tag)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーのタグは編集できない' do
      other_tag = create(:tag, user: other_user)
      get edit_tag_path(other_tag)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(tags_path)
    end
  end

  describe 'PATCH /tags/:id' do
    context '有効なパラメータの場合' do
      let(:new_attributes) do
        {
          name: '更新されたタグ名',
          color: '#00FF00',
        }
      end

      it 'タグを更新する' do
        patch tag_path(tag), params: { tag: new_attributes }
        tag.reload
        expect(tag.name).to eq('更新されたタグ名')
        expect(tag.color).to eq('#00FF00')
      end

      it 'タグ一覧にリダイレクトする' do
        patch tag_path(tag), params: { tag: new_attributes }
        expect(response).to redirect_to(tags_path)
      end

      it '成功メッセージを表示する' do
        patch tag_path(tag), params: { tag: new_attributes }
        follow_redirect!
        expect(response.body).to include('タグを更新しました')
      end
    end

    context '無効なパラメータの場合' do
      it 'タグを更新しない' do
        original_name = tag.name
        patch tag_path(tag), params: { tag: invalid_attributes }
        tag.reload
        expect(tag.name).to eq(original_name)
      end

      it 'editテンプレートを再表示する' do
        patch tag_path(tag), params: { tag: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /tags/:id' do
    it 'タグを削除する' do
      tag_to_delete = create(:tag, user: user)
      expect do
        delete tag_path(tag_to_delete)
      end.to change(Tag, :count).by(-1)
    end

    it 'タグ一覧にリダイレクトする' do
      delete tag_path(tag)
      expect(response).to redirect_to(tags_path)
    end

    it '成功メッセージを表示する' do
      delete tag_path(tag)
      follow_redirect!
      expect(response.body).to include('タグを削除しました')
    end
  end

  describe '認証されていない場合' do
    before do
      sign_out user
    end

    it 'indexにアクセスできない' do
      get tags_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'newにアクセスできない' do
      get new_tag_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'createにアクセスできない' do
      post tags_path, params: { tag: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'editにアクセスできない' do
      get edit_tag_path(tag)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updateにアクセスできない' do
      patch tag_path(tag), params: { tag: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroyにアクセスできない' do
      delete tag_path(tag)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
