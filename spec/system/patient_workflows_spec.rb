require 'rails_helper'

RSpec.describe '患者管理ワークフロー', type: :system do
  let(:user) { create(:user) }

  before do
    login_as user
  end

  describe '基本的な患者管理フロー' do
    it 'ユーザーが患者を登録・閲覧・削除できる', js: true do
      # 患者一覧にアクセス
      visit patients_path
      expect(page).to have_content('患者一覧')
      expect(page).to have_content('まだ患者が登録されていません')

      # 新規患者登録
      click_link '新しい患者を登録'
      expect(current_path).to eq(new_patient_path)

      # フォームに入力（ラベルテキストで指定）
      fill_in '氏名', with: 'テスト患者'
      select '男性', from: '性別'
      fill_in '生年月日', with: '1990-01-01'
      fill_in '電話番号', with: '090-1234-5678'

      click_button '保存'

      # 登録成功を確認
      expect(page).to have_content('患者が正常に登録されました')
      expect(page).to have_content('テスト患者')
      expect(page).to have_content('090-1234-5678')

      # 一覧に戻って表示を確認
      visit patients_path
      expect(page).to have_content('テスト患者')
      expect(page).not_to have_content('まだ患者が登録されていません')

      # 削除
      accept_confirm do
        click_button '削除', match: :first
      end

      expect(page).to have_content('患者が正常に削除されました')
      expect(page).to have_content('まだ患者が登録されていません')
    end
  end
end
