import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-modal"
export default class extends Controller {
  static targets = ["modal", "image", "currentIndex", "totalImages", "prevButton", "nextButton", "container"]
  static values = {
    urls: Array,
    currentIndex: { type: Number, default: 0 }
  }

  connect() {
    console.log("Image modal controller connected")
    console.log("URLs:", this.urlsValue)
    this.updateNavigationButtons()
  }

  open(event) {
    console.log("Opening modal, index:", event.currentTarget.dataset.index)
    const index = parseInt(event.currentTarget.dataset.index)
    this.currentIndexValue = index
    this.modalTarget.style.display = "flex"
    console.log("Modal display set to flex")
    this.updateImage()
    this.updateNavigationButtons()
  }

  close(event) {
    if (event) {
      event.stopPropagation()
    }
    this.modalTarget.style.display = "none"
  }

  closeOnBackground(event) {
    if (event.target === this.modalTarget) {
      this.close(event)
    }
  }

  updateImage() {
    this.imageTarget.src = this.urlsValue[this.currentIndexValue]
    this.currentIndexTarget.textContent = this.currentIndexValue + 1
    this.totalImagesTarget.textContent = this.urlsValue.length
  }

  updateNavigationButtons() {
    if (this.urlsValue.length <= 1) {
      this.prevButtonTarget.style.display = "none"
      this.nextButtonTarget.style.display = "none"
    } else {
      this.prevButtonTarget.style.display = "flex"
      this.nextButtonTarget.style.display = "flex"
    }
  }

  navigate(event) {
    event.stopPropagation()
    const direction = parseInt(event.currentTarget.dataset.direction)
    this.currentIndexValue += direction

    // 循環させる
    if (this.currentIndexValue < 0) {
      this.currentIndexValue = this.urlsValue.length - 1
    } else if (this.currentIndexValue >= this.urlsValue.length) {
      this.currentIndexValue = 0
    }

    this.updateImage()
  }

  handleKeydown(event) {
    if (this.modalTarget.style.display === "none") return

    if (event.key === "ArrowLeft") {
      this.currentIndexValue--
      if (this.currentIndexValue < 0) {
        this.currentIndexValue = this.urlsValue.length - 1
      }
      this.updateImage()
    } else if (event.key === "ArrowRight") {
      this.currentIndexValue++
      if (this.currentIndexValue >= this.urlsValue.length) {
        this.currentIndexValue = 0
      }
      this.updateImage()
    } else if (event.key === "Escape") {
      this.close()
    }
  }

  // スワイプ対応
  touchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
  }

  touchEnd(event) {
    this.touchEndX = event.changedTouches[0].screenX
    this.handleSwipe()
  }

  handleSwipe() {
    const swipeThreshold = 50
    const diff = this.touchStartX - this.touchEndX

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        // 左スワイプ = 次の画像
        this.currentIndexValue++
        if (this.currentIndexValue >= this.urlsValue.length) {
          this.currentIndexValue = 0
        }
      } else {
        // 右スワイプ = 前の画像
        this.currentIndexValue--
        if (this.currentIndexValue < 0) {
          this.currentIndexValue = this.urlsValue.length - 1
        }
      }
      this.updateImage()
    }
  }
}
