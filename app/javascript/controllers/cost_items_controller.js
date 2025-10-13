import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  connect() {
    this.loadCostSheets()
    this.setupEventListeners()
    this.updateAllTotals()
  }

  loadCostSheets() {
    const costSheetsContainer = document.querySelector('[data-cost-sheets]')
    if (costSheetsContainer) {
      try {
        this.costSheets = JSON.parse(costSheetsContainer.dataset.costSheets)
      } catch (e) {
        console.error('CostSheetデータの読み込みに失敗しました', e)
        this.costSheets = []
      }
    } else {
      this.costSheets = []
    }
  }

  setupEventListeners() {
    // 「項目を追加」ボタン
    const addButton = document.getElementById('add-cost-item')
    if (addButton) {
      addButton.addEventListener('click', (e) => this.addItem(e))
    }

    // 既存の削除ボタンと計算フィールドにイベントリスナーを設定
    this.attachRowEventListeners()
  }

  addItem(e) {
    e.preventDefault()

    const template = document.getElementById('cost-item-template')
    if (!template) return

    const content = template.content.cloneNode(true)
    const newId = new Date().getTime()
    const html = content.firstElementChild.outerHTML.replace(/NEW_RECORD/g, newId)

    const container = document.getElementById('cost-items-container')
    container.insertAdjacentHTML('beforeend', html)

    this.attachRowEventListeners()
  }

  attachRowEventListeners() {
    // 削除ボタン
    document.querySelectorAll('.remove-cost-item').forEach(button => {
      button.replaceWith(button.cloneNode(true)) // 重複イベント防止
    })
    document.querySelectorAll('.remove-cost-item').forEach(button => {
      button.addEventListener('click', (e) => this.removeItem(e))
    })

    // 数量・単価フィールドの変更イベント
    document.querySelectorAll('.quantity-field, .unit-price-field').forEach(field => {
      field.replaceWith(field.cloneNode(true)) // 重複イベント防止
    })
    document.querySelectorAll('.quantity-field, .unit-price-field').forEach(field => {
      field.addEventListener('input', (e) => this.calculateRowTotal(e.target))
    })

    // CostSheet選択ドロップダウンの変更イベント
    document.querySelectorAll('.cost-sheet-select').forEach(select => {
      select.replaceWith(select.cloneNode(true)) // 重複イベント防止
    })
    document.querySelectorAll('.cost-sheet-select').forEach(select => {
      select.addEventListener('change', (e) => this.handleCostSheetSelection(e.target))
    })
  }

  handleCostSheetSelection(selectElement) {
    const selectedId = parseInt(selectElement.value)
    if (!selectedId || !this.costSheets) return

    const costSheet = this.costSheets.find(cs => cs.id === selectedId)
    if (!costSheet) return

    const row = selectElement.closest('.cost-item-row')
    if (!row) return

    // 項目名と単価を自動入力
    const itemNameField = row.querySelector('.item-name-field')
    const unitPriceField = row.querySelector('.unit-price-field')

    if (itemNameField) {
      itemNameField.value = costSheet.item_name || ''
    }

    if (unitPriceField) {
      unitPriceField.value = costSheet.standard_price || 0
      // 単価変更後に合計を再計算
      this.calculateRowTotal(unitPriceField)
    }
  }

  removeItem(e) {
    e.preventDefault()
    const row = e.target.closest('.cost-item-row')

    if (row) {
      const destroyField = row.querySelector('.destroy-field')
      if (destroyField) {
        // 既存レコードの場合は_destroyフラグを立てて非表示
        destroyField.value = '1'
        row.style.display = 'none'
      } else {
        // 新規レコードの場合は完全に削除
        row.remove()
      }
    }
  }

  calculateRowTotal(field) {
    const row = field.closest('.cost-item-row')
    if (!row) return

    const quantityField = row.querySelector('.quantity-field')
    const unitPriceField = row.querySelector('.unit-price-field')
    const totalDisplay = row.querySelector('.total-price')

    const quantity = parseFloat(quantityField.value) || 0
    const unitPrice = parseFloat(unitPriceField.value) || 0
    const total = quantity * unitPrice

    totalDisplay.textContent = `¥${total.toLocaleString('ja-JP', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`
  }

  updateAllTotals() {
    document.querySelectorAll('.quantity-field').forEach(field => {
      this.calculateRowTotal(field)
    })
  }
}
