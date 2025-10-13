import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  connect() {
    // ウィンドウリサイズ時にモバイルメニューを閉じる
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
  }

  toggleMobileMenu() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }

  handleResize() {
    // 768px以上（md以上）の場合、モバイルメニューを閉じる
    if (window.innerWidth >= 768) {
      this.mobileMenuTarget.classList.add("hidden")
    }
  }
}
