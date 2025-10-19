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

      # 看護師確認チェックボックスをチェック
      check 'patient_consents[0][nurse_confirmed]'

      # 署名を描画（Canvas APIを使用）
      page.execute_script(<<~JS)
        (function() {
          var visibleSection = Array.from(document.querySelectorAll('[data-consent-forms-target="patientSection"]'))
            .find(function(section) { return !section.classList.contains('hidden'); });

          var canvas = visibleSection.querySelector('canvas[data-signature-target="canvas"]');
          var hiddenField = visibleSection.querySelector('input[data-signature-target="hiddenField"]');

          // canvasのサイズを明示的に設定
          var rect = canvas.getBoundingClientRect();
          var ratio = Math.max(window.devicePixelRatio || 1, 1);
          canvas.width = rect.width * ratio;
          canvas.height = rect.height * ratio;

          // コンテキストを取得して描画
          var ctx = canvas.getContext('2d');
          ctx.scale(ratio, ratio);
          ctx.fillStyle = 'black';
          ctx.fillRect(10, 10, 100, 50);

          // データURLを取得してhiddenFieldに設定
          hiddenField.value = canvas.toDataURL('image/png');
        })();
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

  describe 'PDF機能', js: true do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    after do
      # クリーンアップ
      pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{patient_consent.id}.pdf")
      FileUtils.rm_f(pdf_path)
    end

    it '同意書詳細からPDFを生成・ダウンロードできる' do
      visit medical_record_patient_consent_path(medical_record, patient_consent)

      # 同意書詳細画面が表示される
      expect(page).to have_content('同意書詳細')
      expect(page).to have_content('美容施術同意書')
      expect(page).to have_content(patient.name)

      # PDF生成ボタンをクリック
      click_button 'PDF生成'

      # 成功メッセージが表示される
      expect(page).to have_content('PDFを生成しました')

      # PDFダウンロードリンクが表示される
      expect(page).to have_link('PDFダウンロード')
    end

    it '同意書一覧から詳細画面に遷移できる' do
      visit medical_record_patient_consents_path(medical_record)

      # 同意書一覧が表示される
      expect(page).to have_content('同意書一覧')
      expect(page).to have_content('美容施術同意書')

      # 詳細リンクをクリック
      click_link '詳細'

      # 同意書詳細画面に遷移する
      expect(page).to have_current_path(medical_record_patient_consent_path(medical_record, patient_consent))
      expect(page).to have_content('同意書詳細')
    end
  end

  describe 'アクセス制御' do
    it '未ログイン時はログイン画面にリダイレクトされる' do
      sign_out user
      visit new_medical_record_patient_consent_path(medical_record)

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe '同意書削除', js: true do
    let!(:patient_consent) do
      create(:patient_consent, :with_responses,
             medical_record: medical_record,
             patient: patient,
             user: user,
             facility_doctor: facility_doctor,
             consent_form_template: consent_template)
    end

    it '同意書詳細画面から削除できる' do
      visit medical_record_patient_consent_path(medical_record, patient_consent)

      expect(page).to have_content('同意書詳細')

      # 削除ボタンをクリック
      accept_confirm do
        click_button '同意書を削除'
      end

      # カルテ詳細画面にリダイレクトされる
      expect(page).to have_current_path(medical_record_path(medical_record))
      expect(page).to have_content('同意書を削除しました')

      # 同意書が削除されていることを確認
      expect(PatientConsent.exists?(patient_consent.id)).to be false
    end
  end

  describe '署名バリデーション', js: true do
    it '署名なしで送信するとアラートが表示される' do
      visit new_medical_record_patient_consent_path(medical_record)

      # テンプレートを選択してStep 2に進む
      check '美容施術同意書'
      select '山田太郎', from: 'patient_consents[0][facility_doctor_id]'
      click_button '患者に渡す →'

      # Step 2が表示される
      expect(page).to have_content('Step 2: 患者確認・署名')

      # 必須チェック項目をチェック
      first('input[type="checkbox"][required]').check

      # 看護師確認チェックボックスをチェック
      check 'patient_consents[0][nurse_confirmed]'

      # 署名なしで「同意する」をクリック
      accept_alert do
        click_button '同意する'
      end

      # フォーム送信が阻止され、Step 2に留まる
      expect(page).to have_content('Step 2: 患者確認・署名')
      expect(page).not_to have_content('同意書を作成しました')
    end

    it '看護師確認なしで送信するとアラートが表示される' do
      visit new_medical_record_patient_consent_path(medical_record)

      # テンプレートを選択してStep 2に進む
      check '美容施術同意書'
      select '山田太郎', from: 'patient_consents[0][facility_doctor_id]'
      click_button '患者に渡す →'

      # 必須チェック項目をチェック
      first('input[type="checkbox"][required]').check

      # 署名を描画
      page.execute_script(<<~JS)
        (function() {
          var visibleSection = Array.from(document.querySelectorAll('[data-consent-forms-target="patientSection"]'))
            .find(function(section) { return !section.classList.contains('hidden'); });

          var canvas = visibleSection.querySelector('canvas[data-signature-target="canvas"]');
          var hiddenField = visibleSection.querySelector('input[data-signature-target="hiddenField"]');

          var rect = canvas.getBoundingClientRect();
          var ratio = Math.max(window.devicePixelRatio || 1, 1);
          canvas.width = rect.width * ratio;
          canvas.height = rect.height * ratio;

          var ctx = canvas.getContext('2d');
          ctx.scale(ratio, ratio);
          ctx.fillStyle = 'black';
          ctx.fillRect(10, 10, 100, 50);

          hiddenField.value = canvas.toDataURL('image/png');
        })();
      JS

      # 看護師確認なしで「同意する」をクリック
      accept_alert do
        click_button '同意する'
      end

      # フォーム送信が阻止され、Step 2に留まる
      expect(page).to have_content('Step 2: 患者確認・署名')
      expect(page).not_to have_content('同意書を作成しました')
    end

    it '署名ありの場合は正常に送信できる' do
      visit new_medical_record_patient_consent_path(medical_record)

      # テンプレートを選択してStep 2に進む
      check '美容施術同意書'
      select '山田太郎', from: 'patient_consents[0][facility_doctor_id]'
      click_button '患者に渡す →'

      # 必須チェック項目をチェック
      first('input[type="checkbox"][required]').check

      # 看護師確認チェックボックスをチェック
      check 'patient_consents[0][nurse_confirmed]'

      # 署名を描画（表示されているpatientSection内のcanvasとhiddenFieldを確実に取得）
      page.execute_script(<<~JS)
        (function() {
          // 表示されている（hiddenクラスがない）patientSection内のcanvasを取得
          var visibleSection = Array.from(document.querySelectorAll('[data-consent-forms-target="patientSection"]'))
            .find(function(section) { return !section.classList.contains('hidden'); });

          if (!visibleSection) {
            throw new Error('表示されているpatientSectionが見つかりません');
          }

          var canvas = visibleSection.querySelector('canvas[data-signature-target="canvas"]');
          var hiddenField = visibleSection.querySelector('input[data-signature-target="hiddenField"]');
          var clearButton = visibleSection.querySelector('button[data-signature-target="clearButton"]');

          if (!canvas || !hiddenField) {
            throw new Error('canvasまたはhiddenFieldが見つかりません');
          }

          // canvasのサイズを明示的に設定
          var rect = canvas.getBoundingClientRect();
          var ratio = Math.max(window.devicePixelRatio || 1, 1);
          canvas.width = rect.width * ratio;
          canvas.height = rect.height * ratio;

          // コンテキストを取得して描画
          var ctx = canvas.getContext('2d');
          ctx.scale(ratio, ratio);
          ctx.fillStyle = 'black';
          ctx.fillRect(10, 10, 100, 50);

          // データURLを取得してhiddenFieldに設定
          hiddenField.value = canvas.toDataURL('image/png');

          if (clearButton) clearButton.disabled = false;
        })();
      JS

      # JavaScriptの実行完了を待つ
      expect(page).to have_css('button[data-signature-target="clearButton"]:not([disabled])', wait: 2)

      # 「同意する」ボタンをクリック
      click_button '同意する'

      # 成功メッセージが表示される
      expect(page).to have_current_path(medical_record_path(medical_record))
      expect(page).to have_content('1件の同意書を作成しました')
    end
  end
end
