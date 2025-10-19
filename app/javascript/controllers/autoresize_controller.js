import { Controller } from "@hotwired/stimulus"

/**
 * テキストエリア自動リサイズ用Stimulusコントローラー
 *
 * テキストエリアの内容に応じて高さを自動調整
 * 改行やテキスト追加で自動的に広がる
 *
 * 使用方法:
 * <textarea data-controller="autoresize" data-action="input->autoresize#resize">
 */
export default class extends Controller {
  /**
   * コントローラー接続時に初期サイズを設定
   */
  connect() {
    this.resize()
  }

  /**
   * テキスト入力時に高さを調整
   */
  resize() {
    // 一旦高さをリセットしてscrollHeightを正確に取得
    this.element.style.height = 'auto'

    // scrollHeightに基づいて高さを設定
    // 最小高さは2行分（rows属性の値）
    const minHeight = this.element.scrollHeight
    this.element.style.height = `${minHeight}px`
  }
}
