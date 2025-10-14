import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="questionnaire"
export default class extends Controller {
  static targets = [
    "medicalConditionsDetail",
    "allergiesDetail",
    "medicationsDetail",
    "surgeriesDetail",
    "pastTreatmentsDetail",
  ]

  // 既往歴の表示/非表示
  toggleMedicalConditions(event) {
    const hasConditions = event.target.value === "true"
    this.medicalConditionsDetailTarget.classList.toggle("hidden", !hasConditions)
  }

  // アレルギーの表示/非表示
  toggleAllergies(event) {
    const hasAllergies = event.target.value === "true"
    this.allergiesDetailTarget.classList.toggle("hidden", !hasAllergies)
  }

  // 服薬状況の表示/非表示
  toggleMedications(event) {
    const takingMeds = event.target.value === "true"
    this.medicationsDetailTarget.classList.toggle("hidden", !takingMeds)
  }

  // 手術歴の表示/非表示
  toggleSurgeries(event) {
    const hasSurgeries = event.target.value === "true"
    this.surgeriesDetailTarget.classList.toggle("hidden", !hasSurgeries)
  }

  // 過去のアートメイク経験の表示/非表示
  togglePastTreatments(event) {
    const hasExperience = event.target.value === "true"
    this.pastTreatmentsDetailTarget.classList.toggle("hidden", !hasExperience)
  }

  // 薬物アレルギー詳細の表示/非表示
  toggleDrugAllergyDetail(event) {
    const drugAllergyDetail = document.getElementById("drug_allergy_detail")
    if (drugAllergyDetail) {
      drugAllergyDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // 食物アレルギー詳細の表示/非表示
  toggleFoodAllergyDetail(event) {
    const foodAllergyDetail = document.getElementById("food_allergy_detail")
    if (foodAllergyDetail) {
      foodAllergyDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // その他アレルギー詳細の表示/非表示
  toggleOtherAllergyDetail(event) {
    const otherAllergyDetail = document.getElementById("other_allergy_detail")
    if (otherAllergyDetail) {
      otherAllergyDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // サプリメント詳細の表示/非表示
  toggleSupplementDetail(event) {
    const supplementDetail = document.getElementById("supplement_detail")
    if (supplementDetail) {
      supplementDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // その他服薬詳細の表示/非表示
  toggleOtherMedicationDetail(event) {
    const otherMedDetail = document.getElementById("other_medication_detail")
    if (otherMedDetail) {
      otherMedDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // その他施術詳細の表示/非表示
  toggleOtherTreatmentDetail(event) {
    const otherTreatmentDetail = document.getElementById("other_treatment_detail")
    if (otherTreatmentDetail) {
      otherTreatmentDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // その他医療情報詳細の表示/非表示
  toggleOtherConditionDetail(event) {
    const otherConditionDetail = document.getElementById("other_condition_detail")
    if (otherConditionDetail) {
      otherConditionDetail.classList.toggle("hidden", !event.target.checked)
    }
  }

  // フォーム送信前にチェックボックスデータをJSON形式に変換
  handleSubmit(event) {
    // 既往歴・治療中の病気
    this.aggregateCheckboxData("medical_conditions[]", "medical_conditions_json")

    // アレルギー
    const allergies = []
    const allergyCheckboxes = this.element.querySelectorAll('input[name="allergies[]"]:checked')
    allergyCheckboxes.forEach(checkbox => {
      allergies.push(checkbox.value)
    })

    // アレルギー詳細テキスト入力を追加
    const drugAllergyDetail = document.getElementById("drug_allergy_detail_text")
    if (drugAllergyDetail && drugAllergyDetail.value.trim()) {
      allergies.push(`薬物: ${drugAllergyDetail.value.trim()}`)
    }
    const foodAllergyDetail = document.getElementById("food_allergy_detail_text")
    if (foodAllergyDetail && foodAllergyDetail.value.trim()) {
      allergies.push(`食物: ${foodAllergyDetail.value.trim()}`)
    }
    const otherAllergyDetail = document.getElementById("other_allergy_detail_text")
    if (otherAllergyDetail && otherAllergyDetail.value.trim()) {
      allergies.push(`その他: ${otherAllergyDetail.value.trim()}`)
    }

    this.setHiddenFieldValue("allergies_json", allergies)

    // 服薬中の薬
    const medications = []
    const medicationCheckboxes = this.element.querySelectorAll('input[name="medications[]"]:checked')
    medicationCheckboxes.forEach(checkbox => {
      medications.push(checkbox.value)
    })

    // 服薬詳細テキスト入力を追加
    const supplementDetail = document.getElementById("supplement_detail_text")
    if (supplementDetail && supplementDetail.value.trim()) {
      medications.push(`サプリメント: ${supplementDetail.value.trim()}`)
    }
    const otherMedicationDetail = document.getElementById("other_medication_detail_text")
    if (otherMedicationDetail && otherMedicationDetail.value.trim()) {
      medications.push(`その他: ${otherMedicationDetail.value.trim()}`)
    }

    this.setHiddenFieldValue("current_medications_json", medications)

    // 手術歴
    const surgeries = []
    const surgeryDetail = document.getElementById("surgery_detail_text")
    if (surgeryDetail && surgeryDetail.value.trim()) {
      surgeries.push(surgeryDetail.value.trim())
    }
    this.setHiddenFieldValue("past_surgeries_json", surgeries)

    // 妊娠・授乳状況
    const pregnancy = []
    const pregnancyCheckboxes = this.element.querySelectorAll('input[name="pregnancy_status[]"]:checked')
    pregnancyCheckboxes.forEach(checkbox => {
      pregnancy.push(checkbox.value)
    })
    this.setHiddenFieldValue("pregnancy_info_json", pregnancy)

    // 希望施術部位
    this.aggregateCheckboxData("desired_treatments[]", "desired_treatments_json")

    // 過去のアートメイク経験
    const pastTreatments = []
    const pastTreatmentCheckboxes = this.element.querySelectorAll('input[name="past_treatment_parts[]"]:checked')
    pastTreatmentCheckboxes.forEach(checkbox => {
      pastTreatments.push(checkbox.value)
    })

    // 過去施術詳細テキスト入力を追加
    const otherTreatmentDetail = document.getElementById("other_treatment_detail_text")
    if (otherTreatmentDetail && otherTreatmentDetail.value.trim()) {
      pastTreatments.push(`その他: ${otherTreatmentDetail.value.trim()}`)
    }

    this.setHiddenFieldValue("past_treatments_json", pastTreatments)

    // 肌の状態
    this.aggregateCheckboxData("skin_conditions[]", "skin_conditions_json")

    // その他の気になること
    const otherConcerns = document.getElementById("other_concerns_text")
    if (otherConcerns) {
      const concernsHidden = document.getElementById("other_concerns_json")
      if (concernsHidden) {
        concernsHidden.value = otherConcerns.value.trim()
      }
    }
  }

  // チェックボックス配列を集約してJSON形式に変換
  aggregateCheckboxData(checkboxName, hiddenFieldId) {
    const values = []
    const checkboxes = this.element.querySelectorAll(`input[name="${checkboxName}"]:checked`)
    checkboxes.forEach(checkbox => {
      values.push(checkbox.value)
    })
    this.setHiddenFieldValue(hiddenFieldId, values)
  }

  // 隠しフィールドにJSON値を設定
  setHiddenFieldValue(fieldId, values) {
    // IDで検索（カスタムID指定の場合）
    let hiddenField = document.getElementById(fieldId)

    // IDで見つからない場合、name属性で検索
    if (!hiddenField) {
      // fieldIdから_jsonを除去してname属性を生成
      const fieldName = fieldId.replace('_json', '')
      hiddenField = this.element.querySelector(`input[name="questionnaire[${fieldName}]"]`)
    }

    if (hiddenField) {
      if (Array.isArray(values)) {
        hiddenField.value = JSON.stringify(values)
      } else {
        hiddenField.value = values
      }
    }
  }
}
