import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "toggleText"]

  connect() {
    // URLパラメータに検索条件がある場合は自動展開
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('q')) {
      this.show()
    }
  }

  toggle() {
    if (this.formTarget.classList.contains('hidden')) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.formTarget.classList.remove('hidden')
    this.toggleTextTarget.textContent = '閉じる'
  }

  hide() {
    this.formTarget.classList.add('hidden')
    this.toggleTextTarget.textContent = '展開'
  }
}
