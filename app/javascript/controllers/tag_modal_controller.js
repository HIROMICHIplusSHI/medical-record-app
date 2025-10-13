import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event.preventDefault()
    const modal = document.getElementById('tag-modal')
    if (modal) {
      modal.classList.remove('hidden')
      const nameInput = document.getElementById('tag-name-input')
      if (nameInput) {
        nameInput.focus()
      }
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    const modal = document.getElementById('tag-modal')
    if (modal) {
      modal.classList.add('hidden')
      const form = modal.querySelector('form')
      if (form) {
        form.reset()
      }
    }
  }

  async submit(event) {
    event.preventDefault()

    const nameInput = document.getElementById('tag-name-input')
    const categoryInput = document.getElementById('tag-category-input')
    const colorInput = document.getElementById('tag-color-input')

    const formData = new FormData()
    formData.append('tag[name]', nameInput.value)
    formData.append('tag[category]', categoryInput.value)
    formData.append('tag[color]', colorInput.value)

    try {
      const response = await fetch('/tags', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        const data = await response.json()
        // ページをリロードしてタグを表示
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.errors ? data.errors.join('\n') : 'タグの作成に失敗しました')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('タグの作成に失敗しました')
    }
  }
}
