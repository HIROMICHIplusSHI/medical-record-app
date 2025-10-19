import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

// Connects to data-controller="signature"
export default class extends Controller {
  static targets = ["canvas", "hiddenField", "clearButton"]

  connect() {
    this.initializeSignaturePad()
  }

  // 外部から呼び出し可能な再初期化メソッド
  reinitialize() {
    if (this.signaturePad) {
      this.signaturePad.off()
    }
    this.initializeSignaturePad()
  }

  disconnect() {
    if (this.signaturePad) {
      this.signaturePad.off()
    }
  }

  initializeSignaturePad() {
    const canvas = this.canvasTarget

    // Canvas のサイズ設定（親要素に合わせる）
    this.resizeCanvas(canvas)

    // SignaturePad インスタンス作成
    this.signaturePad = new SignaturePad(canvas, {
      backgroundColor: 'rgb(255, 255, 255)',
      penColor: 'rgb(0, 0, 0)',
      minWidth: 1,
      maxWidth: 2.5,
    })

    // 署名が変更されたときのイベントハンドラ
    this.signaturePad.addEventListener("endStroke", () => {
      this.updateHiddenField()
    })

    // ウィンドウリサイズ時の対応
    window.addEventListener("resize", () => {
      this.resizeCanvas(canvas)
    })
  }

  resizeCanvas(canvas) {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const rect = canvas.getBoundingClientRect()

    canvas.width = rect.width * ratio
    canvas.height = rect.height * ratio
    canvas.getContext("2d").scale(ratio, ratio)

    // リサイズ後に既存の署名を復元
    if (this.signaturePad && !this.signaturePad.isEmpty()) {
      const data = this.signaturePad.toData()
      this.signaturePad.fromData(data)
    }
  }

  updateHiddenField() {
    if (!this.signaturePad.isEmpty()) {
      const dataURL = this.signaturePad.toDataURL("image/png")
      this.hiddenFieldTarget.value = dataURL
      this.clearButtonTarget.disabled = false
    } else {
      this.hiddenFieldTarget.value = ""
      this.clearButtonTarget.disabled = true
    }
  }

  clear() {
    this.signaturePad.clear()
    this.updateHiddenField()
  }
}
