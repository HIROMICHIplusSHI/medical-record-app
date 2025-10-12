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
}
