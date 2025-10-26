import { Controller } from "@hotwired/stimulus"

// アコーディオンの展開・折りたたみを制御
export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
