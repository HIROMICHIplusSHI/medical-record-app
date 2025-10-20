import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="announcement"
export default class extends Controller {
  dismiss(event) {
    const announcementId = event.params.announcementId
    const announcementElement = document.querySelector(`[data-announcement-id="${announcementId}"]`)

    if (!announcementElement) return

    // フェードアウトアニメーション
    announcementElement.style.transition = 'opacity 0.3s ease-out'
    announcementElement.style.opacity = '0'

    setTimeout(() => {
      announcementElement.remove()

      // セッションに保存（サーバーサイド）
      fetch('/home/dismiss_announcement', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ announcement_id: announcementId })
      })
    }, 300)
  }
}
