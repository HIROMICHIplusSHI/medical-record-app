require 'rails_helper'

RSpec.describe 'ConsentFormTemplates', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:template) { create(:consent_form_template, user: user) }
  let(:valid_attributes) do
    {
      title: 'アートメイク施術同意書',
      description: '施術前に必ずご確認ください。',
      is_active: true,
    }
  end
  let(:invalid_attributes) do
    {
      title: '',
    }
  end

  before do
    sign_in user
  end

  describe 'GET /consent_form_templates' do
    it '正常にレスポンスを返す' do
      get consent_form_templates_path
      expect(response).to have_http_status(:success)
    end

    it 'ユーザーのテンプレートのみを表示する' do
      create(:consent_form_template, user: user, title: 'ユーザーのテンプレート')
      create(:consent_form_template, user: other_user, title: '他のユーザーのテンプレート')

      get consent_form_templates_path
      expect(response.body).to include('ユーザーのテンプレート')
      expect(response.body).not_to include('他のユーザーのテンプレート')
    end
  end

  describe 'GET /consent_form_templates/:id' do
    it '正常にレスポンスを返す' do
      get consent_form_template_path(template)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーのテンプレートにはアクセスできない' do
      other_template = create(:consent_form_template, user: other_user)
      get consent_form_template_path(other_template)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(consent_form_templates_path)
    end
  end

  describe 'GET /consent_form_templates/new' do
    it '正常にレスポンスを返す' do
      get new_consent_form_template_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /consent_form_templates' do
    context 'チェック項目も同時に作成する場合' do
      let(:template_with_items_attributes) do
        {
          title: 'アートメイク施術同意書',
          description: '施術前に必ずご確認ください。',
          consent_form_items_attributes: [
            { content: '施術にはリスクがあることを理解しました', position: 1, is_required: true },
            { content: 'アレルギーの有無を正しく申告しました', position: 2, is_required: true },
            { content: 'その他の注意事項を確認しました', position: 3, is_required: false },
          ],
        }
      end

      it 'テンプレートとチェック項目を同時に作成する' do
        expect do
          post consent_form_templates_path, params: { consent_form_template: template_with_items_attributes }
        end.to change(ConsentFormTemplate, :count).by(1)
                                                  .and change(ConsentFormItem, :count).by(3)
      end

      it 'チェック項目が正しく保存される' do
        post consent_form_templates_path, params: { consent_form_template: template_with_items_attributes }
        template = ConsentFormTemplate.last
        expect(template.consent_form_items.count).to eq(3)
        expect(template.consent_form_items.first.content).to eq('施術にはリスクがあることを理解しました')
        expect(template.consent_form_items.first.is_required).to be true
      end
    end

    context '有効なパラメータの場合' do
      it '新しいテンプレートを作成する' do
        expect do
          post consent_form_templates_path, params: { consent_form_template: valid_attributes }
        end.to change(ConsentFormTemplate, :count).by(1)
      end

      it '作成したテンプレートにリダイレクトする' do
        post consent_form_templates_path, params: { consent_form_template: valid_attributes }
        expect(response).to redirect_to(consent_form_template_path(ConsentFormTemplate.last))
      end

      it '成功メッセージを表示する' do
        post consent_form_templates_path, params: { consent_form_template: valid_attributes }
        follow_redirect!
        expect(response.body).to include('同意書テンプレートが正常に作成されました')
      end
    end

    context '無効なパラメータの場合' do
      it 'テンプレートを作成しない' do
        expect do
          post consent_form_templates_path, params: { consent_form_template: invalid_attributes }
        end.not_to change(ConsentFormTemplate, :count)
      end

      it 'newテンプレートを再表示する' do
        post consent_form_templates_path, params: { consent_form_template: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /consent_form_templates/:id/edit' do
    it '正常にレスポンスを返す' do
      get edit_consent_form_template_path(template)
      expect(response).to have_http_status(:success)
    end

    it '他のユーザーのテンプレートは編集できない' do
      other_template = create(:consent_form_template, user: other_user)
      get edit_consent_form_template_path(other_template)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(consent_form_templates_path)
    end
  end

  describe 'PATCH /consent_form_templates/:id' do
    context 'チェック項目も同時に更新する場合' do
      let!(:template_with_items) do
        create(:consent_form_template, user: user, title: '既存テンプレート').tap do |t|
          create(:consent_form_item, consent_form_template: t, content: '既存項目1', position: 1)
          create(:consent_form_item, consent_form_template: t, content: '既存項目2', position: 2)
        end
      end

      let(:update_with_items_attributes) do
        {
          title: '更新されたテンプレート',
          consent_form_items_attributes: [
            { id: template_with_items.consent_form_items.first.id, content: '更新された項目1', position: 1 },
            { id: template_with_items.consent_form_items.second.id, content: '更新された項目2', position: 2 },
            { content: '新規項目3', position: 3, is_required: true },
          ],
        }
      end

      it '既存項目を更新し、新規項目を追加する' do
        expect do
          patch consent_form_template_path(template_with_items),
                params: { consent_form_template: update_with_items_attributes }
        end.to change { template_with_items.reload.consent_form_items.count }.by(1)

        expect(template_with_items.consent_form_items.first.content).to eq('更新された項目1')
        expect(template_with_items.consent_form_items.last.content).to eq('新規項目3')
      end

      it '項目を削除できる（_destroyフラグ）' do
        item_to_delete = template_with_items.consent_form_items.first
        delete_attributes = {
          consent_form_items_attributes: [
            { id: item_to_delete.id, _destroy: '1' },
          ],
        }

        expect do
          patch consent_form_template_path(template_with_items), params: { consent_form_template: delete_attributes }
        end.to change { template_with_items.reload.consent_form_items.count }.by(-1)
      end
    end

    context '有効なパラメータの場合' do
      let(:new_attributes) do
        {
          title: '更新された同意書',
          description: '更新された説明',
        }
      end

      it 'テンプレートを更新する' do
        patch consent_form_template_path(template), params: { consent_form_template: new_attributes }
        template.reload
        expect(template.title).to eq('更新された同意書')
        expect(template.description).to eq('更新された説明')
      end

      it '更新したテンプレートにリダイレクトする' do
        patch consent_form_template_path(template), params: { consent_form_template: new_attributes }
        expect(response).to redirect_to(consent_form_template_path(template))
      end

      it '成功メッセージを表示する' do
        patch consent_form_template_path(template), params: { consent_form_template: new_attributes }
        follow_redirect!
        expect(response.body).to include('同意書テンプレートが正常に更新されました')
      end
    end

    context '無効なパラメータの場合' do
      it 'テンプレートを更新しない' do
        original_title = template.title
        patch consent_form_template_path(template), params: { consent_form_template: invalid_attributes }
        template.reload
        expect(template.title).to eq(original_title)
      end

      it 'editテンプレートを再表示する' do
        patch consent_form_template_path(template), params: { consent_form_template: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it '他のユーザーのテンプレートは更新できない' do
      other_template = create(:consent_form_template, user: other_user)
      patch consent_form_template_path(other_template), params: { consent_form_template: { title: '不正な更新' } }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(consent_form_templates_path)
    end
  end

  describe 'DELETE /consent_form_templates/:id' do
    it 'テンプレートを削除する' do
      template_to_delete = create(:consent_form_template, user: user)
      expect do
        delete consent_form_template_path(template_to_delete)
      end.to change(ConsentFormTemplate, :count).by(-1)
    end

    it 'テンプレート一覧にリダイレクトする' do
      delete consent_form_template_path(template)
      expect(response).to redirect_to(consent_form_templates_path)
    end

    it '成功メッセージを表示する' do
      delete consent_form_template_path(template)
      follow_redirect!
      expect(response.body).to include('同意書テンプレートが正常に削除されました')
    end

    it '他のユーザーのテンプレートは削除できない' do
      other_template = create(:consent_form_template, user: other_user)
      expect do
        delete consent_form_template_path(other_template)
      end.not_to change(ConsentFormTemplate, :count)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(consent_form_templates_path)
    end
  end

  describe '認証されていない場合' do
    before do
      sign_out user
    end

    it 'indexにアクセスできない' do
      get consent_form_templates_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'showにアクセスできない' do
      get consent_form_template_path(template)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'newにアクセスできない' do
      get new_consent_form_template_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'createにアクセスできない' do
      post consent_form_templates_path, params: { consent_form_template: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'editにアクセスできない' do
      get edit_consent_form_template_path(template)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updateにアクセスできない' do
      patch consent_form_template_path(template), params: { consent_form_template: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroyにアクセスできない' do
      delete consent_form_template_path(template)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
