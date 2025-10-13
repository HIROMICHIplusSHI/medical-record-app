import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="photo-preview"
export default class extends Controller {
  static targets = ["input", "preview", "container"]
  static values = { maxFiles: { type: Number, default: 5 } }

  connect() {
    // 配列でファイルを保持するように変更
    this.selectedFilesArray = []
  }

  disconnect() {
    // Clean up any pending FileReader operations and memory
    if (this.containerTarget) {
      this.containerTarget.innerHTML = ''
    }
    this.selectedFilesArray = []
  }

  preview(event) {
    const files = Array.from(event.target.files)

    // 既存のファイル数と新しいファイル数の合計をチェック
    const totalFiles = this.selectedFilesArray.length + files.length
    if (totalFiles > this.maxFilesValue) {
      alert(`画像は最大${this.maxFilesValue}枚までアップロードできます`)
      event.target.value = ""
      return
    }

    files.forEach(file => {
      // 画像ファイルのみ許可
      if (!file.type.startsWith('image/')) {
        return
      }

      // ファイルサイズチェック（10MB）
      if (file.size > 10 * 1024 * 1024) {
        alert(`${file.name}のサイズが10MBを超えています`)
        return
      }

      // 配列に追加
      this.selectedFilesArray.push(file)
    })

    // プレビューを全て再描画
    this.refreshPreviews()

    // DataTransferを使ってinput要素を更新（プレビュー後に実行）
    this.updateInputFiles()
  }

  updateInputFiles() {
    // 配列からDataTransferを作成してinputに設定
    const dataTransfer = new DataTransfer()
    this.selectedFilesArray.forEach(file => {
      dataTransfer.items.add(file)
    })
    this.inputTarget.files = dataTransfer.files
  }

  refreshPreviews() {
    // プレビューを全てクリア
    this.containerTarget.innerHTML = ''

    // 全てのファイルのプレビューを表示
    this.selectedFilesArray.forEach((file, index) => {
      this.showPreviewAtIndex(file, index)
    })
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation()

    const indexToRemove = parseInt(event.currentTarget.dataset.index)

    // 配列から指定インデックスを削除
    if (indexToRemove >= 0 && indexToRemove < this.selectedFilesArray.length) {
      this.selectedFilesArray.splice(indexToRemove, 1)
    }

    // input要素を更新
    this.updateInputFiles()

    // プレビューを全て再描画
    this.refreshPreviews()
  }

  showPreviewAtIndex(file, index) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const previewItem = document.createElement('div')
      previewItem.className = 'relative group'
      previewItem.dataset.index = index

      const deleteButton = document.createElement('button')
      deleteButton.type = 'button'
      deleteButton.dataset.action = 'click->photo-preview#remove'
      deleteButton.dataset.index = index
      deleteButton.className = 'bg-red-600 hover:bg-red-700 text-white rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity shadow-lg border-2 border-white'

      deleteButton.innerHTML = `
        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="3">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      `

      // Create filename div safely with textContent to prevent XSS
      const filenameDiv = document.createElement('div')
      filenameDiv.className = 'absolute bottom-2 left-2 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded'
      filenameDiv.textContent = file.name

      previewItem.innerHTML = `
        <img src="${e.target.result}" class="w-full h-40 object-cover rounded-lg shadow-sm">
        <div class="absolute top-2 right-2"></div>
      `

      // Add the button and filename div to the container
      previewItem.querySelector('.absolute.top-2').appendChild(deleteButton)
      previewItem.appendChild(filenameDiv)
      this.containerTarget.appendChild(previewItem)
    }

    reader.readAsDataURL(file)
  }
}
