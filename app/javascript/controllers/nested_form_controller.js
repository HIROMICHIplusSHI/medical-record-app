import { Controller } from "@hotwired/stimulus"

/**
 * ネストフォーム用Stimulusコントローラー
 *
 * 動的なフォーム項目の追加・削除を行う汎用コントローラー
 * 施設医師情報、同意書チェック項目など、複数の用途で使用可能
 *
 * 使用方法:
 * 1. 親要素に data-controller="nested-form" を追加
 * 2. コンテナ要素に data-nested-form-target="container" を追加
 * 3. テンプレート要素に data-nested-form-target="template" を追加
 * 4. 追加ボタンに data-action="click->nested-form#addItem" を追加
 * 5. 削除ボタンに data-action="click->nested-form#removeItem" を追加
 * 6. 各項目のルート要素に data-nested-form-target="item" を追加
 * 7. _destroyフィールドに data-nested-form-target="destroyField" を追加
 */
export default class extends Controller {
  static targets = ["container", "template", "item", "destroyField"]

  /**
   * 新しい項目をフォームに追加
   * テンプレートをクローンして、NEW_RECORDをタイムスタンプで置換
   */
  addItem(e) {
    e.preventDefault()

    if (!this.hasTemplateTarget) {
      console.error('Template target not found')
      return
    }

    // テンプレートをクローン
    const template = this.templateTarget.content.cloneNode(true)

    // NEW_RECORDをユニークなIDで置換（タイムスタンプ使用）
    const newId = new Date().getTime()
    const html = template.firstElementChild.outerHTML.replace(/NEW_RECORD/g, newId)

    // コンテナに追加
    this.containerTarget.insertAdjacentHTML('beforeend', html)

    // 追加した項目の表示順を設定（最後の項目なので、現在のアイテム数）
    const newItem = this.containerTarget.lastElementChild
    const positionField = newItem.querySelector('.position-field')
    if (positionField) {
      const currentItemCount = this.containerTarget.querySelectorAll('[data-nested-form-target="item"]:not([style*="display: none"])').length
      positionField.value = currentItemCount
    }
  }

  /**
   * 項目を削除
   * 既存レコードの場合は_destroyフラグを立てて非表示
   * 新規レコードの場合は完全に削除
   */
  removeItem(e) {
    e.preventDefault()

    // 確認ダイアログを表示
    if (!confirm('この項目を削除してもよろしいですか？')) {
      return
    }

    // 削除ボタンの親要素（項目全体）を取得
    const item = e.target.closest('[data-nested-form-target="item"]')
    if (!item) {
      console.error('Item element not found')
      return
    }

    // _destroyフィールドを取得
    const destroyField = item.querySelector('[data-nested-form-target="destroyField"]')

    if (destroyField) {
      // 既存レコードの場合は_destroyフラグを立てて非表示
      destroyField.value = '1'
      item.style.display = 'none'
    } else {
      // 新規レコードの場合は完全に削除
      item.remove()
    }

    // 削除後、残りの項目の表示順を振り直す
    this.updateAllPositions()
  }

  /**
   * 全ての表示中の項目の表示順を振り直す
   */
  updateAllPositions() {
    const visibleItems = this.containerTarget.querySelectorAll('[data-nested-form-target="item"]:not([style*="display: none"])')
    visibleItems.forEach((item, index) => {
      const positionField = item.querySelector('.position-field')
      if (positionField) {
        positionField.value = index + 1
      }
    })
  }
}
