import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="announcement"
export default class extends Controller {
  // フェードアウトアニメーション時間（ミリ秒）
  static FADE_OUT_DURATION = 300

  dismiss(event) {
    const announcementId = event.params.announcementId
    const announcementElement = document.querySelector(`[data-announcement-id="${announcementId}"]`)

    if (!announcementElement) return

    // CSRFトークン取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (!csrfToken) {
      console.error('CSRF token not found')
      return
    }

    // フェードアウトアニメーション
    announcementElement.style.transition = `opacity ${this.constructor.FADE_OUT_DURATION}ms ease-out`
    announcementElement.style.opacity = '0'

    setTimeout(() => {
      announcementElement.remove()

      // セッションに保存（サーバーサイド）
      fetch('/dashboard/dismiss_announcement', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken.content
        },
        body: JSON.stringify({ announcement_id: announcementId })
      })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
      })
      .catch(error => {
        console.error('Failed to dismiss announcement:', error)
        // エラー時は要素を復元
        document.body.insertAdjacentHTML('afterbegin', announcementElement.outerHTML)
      })
    }, this.constructor.FADE_OUT_DURATION)
  }
}
