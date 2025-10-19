require 'rails_helper'

RSpec.describe 'PatientConsents', type: :system do
  let!(:user) { create(:user) }
  let!(:facility) { create(:facility, user: user) }
  let!(:patient) { create(:patient, user: user) }
  let!(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }
  let!(:consent_template) { create(:consent_form_template, user: user, title: '美容施術同意書') }
  let!(:facility_doctor) { create(:facility_doctor, facility: facility, name: '山田太郎') }

  before do
    # テンプレートにチェック項目を追加
    create(:consent_form_item,
           consent_form_template: consent_template,
           content: '施術内容について説明を受けました',
           position: 1,
           is_required: true)

    sign_in user
  end

  describe '同意書作成フロー（2ステップ）', js: true do
    it 'Step 1で施術者がテンプレート・医師を選択し、Step 2で患者が確認・署名できる' do
      visit new_medical_record_patient_consent_path(medical_record)

      # 同意書作成画面が表示される
      expect(page).to have_content('同意書作成')
      expect(page).to have_content('美容施術同意書')

      # Step 1のインジケーターが表示される
      expect(page).to have_selector('[data-consent-forms-target="stepIndicator1"]')
      expect(page).to have_content('施術者による準備')

      # 「患者に渡す」ボタンは初期状態では無効
      expect(page).to have_button('患者に渡す →', disabled: true)

      # テンプレートを選択
      check '美容施術同意書'

      # 医師選択フォームが表示される
      expect(page).to have_select('patient_consents[0][facility_doctor_id]')

      # 医師を選択
      select '山田太郎', from: 'patient_consents[0][facility_doctor_id]'

      # 「患者に渡す」ボタンが有効になる
      expect(page).to have_button('患者に渡す →', disabled: false)

      # Step 2に進む
      click_button '患者に渡す →'

      # Step 2が表示される
      expect(page).to have_content('Step 2: 患者確認・署名')
      expect(page).to have_content('患者様へ：')

      # Step 1が非表示になっていることを確認
      expect(page).not_to have_content('Step 1: 施術者による準備', wait: 1)

      # ステップインジケーターが更新される（Step 1が緑、Step 2が青）
      step1_indicator = find('[data-consent-forms-target="stepIndicator1"]')
      step2_indicator = find('[data-consent-forms-target="stepIndicator2"]')
      expect(step1_indicator[:class]).to include('bg-green-600')
      expect(step2_indicator[:class]).to include('bg-blue-600')

      # 必須チェック項目をチェック
      first('input[type="checkbox"][required]').check

      # 署名を描画（Canvas APIを使用）
      page.execute_script(<<~JS)
        const canvas = document.querySelector('canvas[data-signature-target="canvas"]');
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = 'black';
        ctx.fillRect(10, 10, 100, 50);
        const hiddenField = document.querySelector('input[data-signature-target="hiddenField"]');
        hiddenField.value = canvas.toDataURL('image/png');
      JS

      # 「同意する」ボタンをクリック
      click_button '同意する'

      # カルテ詳細画面にリダイレクトされる
      expect(page).to have_current_path(medical_record_path(medical_record))
      expect(page).to have_content('1件の同意書を作成しました')

      # 同意書が表示される
      expect(page).to have_content('美容施術同意書')
      expect(page).to have_content('山田太郎')
      expect(page).to have_content('署名済み')
    end

    it 'Step 2から Step 1に戻ることができる' do
      visit new_medical_record_patient_consent_path(medical_record)

      # Step 1でテンプレート選択
      check '美容施術同意書'
      select '山田太郎', from: 'patient_consents[0][facility_doctor_id]'

      # Step 2に進む
      click_button '患者に渡す →'
      expect(page).to have_content('Step 2: 患者確認・署名')

      # 「戻る」ボタンをクリック
      click_button '← 戻る'

      # Step 1に戻る
      expect(page).to have_content('Step 1: 施術者による準備')
      expect(page).not_to have_content('Step 2: 患者確認・署名', wait: 1)

      # ステップインジケーターが更新される
      step1_indicator = find('[data-consent-forms-target="stepIndicator1"]')
      step2_indicator = find('[data-consent-forms-target="stepIndicator2"]')
      expect(step1_indicator[:class]).to include('bg-blue-600')
      expect(step2_indicator[:class]).to include('bg-gray-200')
    end
  end

  describe 'アクセス制御' do
    it '未ログイン時はログイン画面にリダイレクトされる' do
      sign_out user
      visit new_medical_record_patient_consent_path(medical_record)

      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
