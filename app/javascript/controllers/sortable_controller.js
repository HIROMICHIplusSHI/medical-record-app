import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

/**
 * ドラッグ&ドロップ並び替え用Stimulusコントローラー
 *
 * SortableJSを使用して、リスト項目のドラッグ&ドロップによる並び替えを実現
 * 並び替え後、自動的にサーバーに位置情報を送信して永続化
 *
 * 使用方法:
 * 1. 親要素に data-controller="sortable" を追加
 * 2. data-sortable-url-value に更新用のエンドポイントURLを指定
 * 3. 各項目に data-id 属性でレコードIDを指定
 *
 * 例:
 * <div data-controller="sortable" data-sortable-url-value="<%= sort_consent_form_items_path(@template) %>">
 *   <div data-id="1">項目1</div>
 *   <div data-id="2">項目2</div>
 * </div>
 */
export default class extends Controller {
  static values = {
    url: String
  }

  /**
   * コントローラー初期化時にSortableを設定
   */
  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: '.drag-handle', // ドラッグハンドルのセレクタ（任意）
      ghostClass: 'sortable-ghost', // ドラッグ中の要素に適用されるクラス
      onEnd: this.end.bind(this)
    })
  }

  /**
   * コントローラー破棄時にSortableをクリーンアップ
   */
  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  /**
   * ドラッグ&ドロップ終了時のハンドラー
   * サーバーに新しい並び順を送信
   */
  end(event) {
    // 並び替えが実際に発生したかチェック
    if (event.oldIndex === event.newIndex) {
      return
    }

    // 全ての項目のIDと新しい位置を収集
    // data-idがない項目（新規追加項目）は除外
    const items = Array.from(this.element.children)
      .filter(item => item.dataset.id) // data-idがある項目のみ
      .map((item, index) => ({
        id: item.dataset.id,
        position: index + 1
      }))

    // 保存済みの項目がない場合は何もしない
    if (items.length === 0) {
      return
    }

    // サーバーに送信
    this.updatePositions(items)
  }

  /**
   * 位置情報をサーバーに送信
   * @param {Array} items - {id, position}の配列
   */
  updatePositions(items) {
    if (!this.hasUrlValue) {
      console.error('Sortable controller: URL value not set')
      return
    }

    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({ items })
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        console.log('Positions updated successfully:', data)
      })
      .catch(error => {
        console.error('Failed to update positions:', error)
        // エラー時は元の位置に戻す
        this.sortable.sort(this.originalOrder)
      })
  }

  /**
   * CSRFトークンを取得
   */
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  /**
   * 元の並び順を保存（エラー時のロールバック用）
   */
  get originalOrder() {
    return Array.from(this.element.children).map(item => item.dataset.id)
  }
}
