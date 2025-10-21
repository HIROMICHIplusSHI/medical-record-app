import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle(event) {
    event.stopPropagation()
    const isExpanded = this.buttonTarget.getAttribute('aria-expanded') === 'true'

    this.menuTarget.classList.toggle("hidden")
    this.buttonTarget.setAttribute('aria-expanded', !isExpanded)
  }

  hide(event) {
    // クリックがこのコントローラーの要素外の場合のみメニューを閉じる
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      this.buttonTarget.setAttribute('aria-expanded', 'false')
    }
  }
}
