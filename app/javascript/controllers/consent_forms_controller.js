import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="consent-forms"
export default class extends Controller {
  static targets = [
    "checkbox",
    "form",
    "step1Content",
    "step2Content",
    "stepIndicator1",
    "stepIndicator2",
    "nextButton",
    "submitButton",
    "patientSection",
    "nurseCheckbox"
  ]

  static values = {
    currentStep: { type: Number, default: 1 }
  }

  connect() {
    this.showCurrentStep()

    // 初期化時、すべての医師選択フォームを無効化（チェックされるまで送信しない）
    this.formTargets.forEach(form => {
      this.disableFormInputs(form)
    })
  }

  toggleTemplate(event) {
    const checkbox = event.target
    const templateId = checkbox.dataset.templateId
    const form = this.formTargets.find(f => f.dataset.templateId === templateId)

    if (form) {
      if (checkbox.checked) {
        form.classList.remove("hidden")
        this.enableFormInputs(form)
      } else {
        form.classList.add("hidden")
        this.disableFormInputs(form)
      }
    }

    // 選択されたテンプレートがあるかチェック
    this.updateNextButtonState()
  }

  updateNextButtonState() {
    const hasSelected = this.checkboxTargets.some(cb => cb.checked)
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = !hasSelected
    }
  }

  goToStep2() {
    // 選択されたテンプレートがあるか確認
    const hasSelected = this.checkboxTargets.some(cb => cb.checked)
    if (!hasSelected) {
      alert('同意書テンプレートを1つ以上選択してください。')
      return
    }

    // チェックされたテンプレートに対応する患者確認セクションのみ表示
    this.checkboxTargets.forEach(checkbox => {
      const templateId = checkbox.dataset.templateId
      const patientSection = this.patientSectionTargets.find(
        section => section.dataset.templateId === templateId
      )

      if (patientSection) {
        if (checkbox.checked) {
          patientSection.classList.remove("hidden")
        } else {
          patientSection.classList.add("hidden")
          // チェックされていないテンプレートの患者セクション内フォームも無効化
          this.disableFormInputs(patientSection)
        }
      }
    })

    this.currentStepValue = 2
    this.showCurrentStep()

    // DOMレンダリング完了を待ってから署名パッドを再初期化
    // 2重のrequestAnimationFrameでレイアウト計算完了を確実に待つ
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.reinitializeSignaturePads()

        // ページ最上部にスクロール
        window.scrollTo({ top: 0, behavior: 'smooth' })
      })
    })
  }

  reinitializeSignaturePads() {
    // 表示されている患者セクション内の署名コントローラーを再初期化
    this.patientSectionTargets.forEach(section => {
      if (!section.classList.contains("hidden")) {
        const signatureElement = section.querySelector('[data-controller="signature"]')
        if (signatureElement) {
          const signatureController = this.application.getControllerForElementAndIdentifier(
            signatureElement,
            "signature"
          )
          if (signatureController && typeof signatureController.reinitialize === 'function') {
            signatureController.reinitialize()
          }
        }
      }
    })
  }

  goBackToStep1() {
    // すべての患者確認セクションを非表示に戻す
    this.patientSectionTargets.forEach(section => {
      section.classList.add("hidden")
      // 患者セクション内のフォームを再有効化
      this.enableFormInputs(section)
    })

    this.currentStepValue = 1
    this.showCurrentStep()

    // ページ最上部にスクロール
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  showCurrentStep() {
    if (this.currentStepValue === 1) {
      // Step 1を表示
      if (this.hasStep1ContentTarget) {
        this.step1ContentTarget.classList.remove("hidden")
        // Step 1のフォームを有効化（チェックされたもののみ）
        this.checkboxTargets.forEach(checkbox => {
          const templateId = checkbox.dataset.templateId
          const form = this.formTargets.find(f => f.dataset.templateId === templateId)
          if (form && checkbox.checked) {
            this.enableFormInputs(form)
          }
        })
      }
      if (this.hasStep2ContentTarget) {
        this.step2ContentTarget.classList.add("hidden")
      }

      // ステップインジケーター更新
      this.updateStepIndicators(1)
    } else {
      // Step 2を表示
      if (this.hasStep1ContentTarget) {
        this.step1ContentTarget.classList.add("hidden")
        // Step 1のフォーム: チェックされていないもののみ無効化
        // チェックされたものは有効なまま（フォーム送信に必要）
        this.checkboxTargets.forEach(checkbox => {
          const templateId = checkbox.dataset.templateId
          const form = this.formTargets.find(f => f.dataset.templateId === templateId)
          if (form && !checkbox.checked) {
            this.disableFormInputs(form)
          }
        })
      }
      if (this.hasStep2ContentTarget) {
        this.step2ContentTarget.classList.remove("hidden")
      }

      // ステップインジケーター更新
      this.updateStepIndicators(2)
    }
  }

  updateStepIndicators(step) {
    if (this.hasStepIndicator1Target && this.hasStepIndicator2Target) {
      if (step === 1) {
        // Step 1アクティブ
        this.stepIndicator1Target.classList.add("bg-blue-600", "text-white")
        this.stepIndicator1Target.classList.remove("bg-gray-200", "text-gray-600")

        this.stepIndicator2Target.classList.add("bg-gray-200", "text-gray-600")
        this.stepIndicator2Target.classList.remove("bg-blue-600", "text-white")
      } else {
        // Step 2アクティブ
        this.stepIndicator1Target.classList.add("bg-green-600", "text-white")
        this.stepIndicator1Target.classList.remove("bg-blue-600", "bg-gray-200", "text-gray-600")

        this.stepIndicator2Target.classList.add("bg-blue-600", "text-white")
        this.stepIndicator2Target.classList.remove("bg-gray-200", "text-gray-600")
      }
    }
  }

  // フォーム内のすべての入力フィールドを無効化
  disableFormInputs(form) {
    const inputs = form.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      input.disabled = true
      // required属性も一時的に削除（HTML5バリデーションを回避）
      if (input.hasAttribute('required')) {
        input.dataset.wasRequired = 'true'
        input.removeAttribute('required')
      }
    })
  }

  // フォーム内のすべての入力フィールドを有効化
  enableFormInputs(form) {
    const inputs = form.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      input.disabled = false
      // 元々required属性があった場合は復元
      if (input.dataset.wasRequired === 'true') {
        input.setAttribute('required', 'required')
        delete input.dataset.wasRequired
      }
    })
  }

  // 看護師確認チェックボックスの状態変更時
  checkNurseConfirmation() {
    // 特に何もしない（HTML5バリデーションに任せる）
    // 必要に応じて送信ボタンの有効/無効を制御することも可能
  }

  // フォーム送信前の署名・看護師確認バリデーション
  validateBeforeSubmit(event) {
    // 表示されているpatientSectionを取得
    const visibleSections = this.patientSectionTargets.filter(section =>
      !section.classList.contains('hidden')
    )

    // 各セクション内の署名データと看護師確認をチェック
    for (const section of visibleSections) {
      // 署名チェック
      const signatureElement = section.querySelector('[data-controller="signature"]')
      if (!signatureElement) continue

      const hiddenField = signatureElement.querySelector('input[data-signature-target="hiddenField"]')
      if (!hiddenField || hiddenField.value === '') {
        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
        alert('署名をお願いします。上記のキャンバスに署名を描いてください。')
        return false
      }

      // 看護師確認チェック
      const nurseCheckbox = section.querySelector('[data-consent-forms-target="nurseCheckbox"]')
      if (nurseCheckbox && !nurseCheckbox.checked) {
        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
        alert('看護師による最終確認が必要です。確認後にチェックを入れてください。')
        return false
      }
    }

    return true
  }
}
