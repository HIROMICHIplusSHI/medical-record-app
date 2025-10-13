import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "nameInput", "categoryInput", "colorInput", "tagList"]

  toggle(event) {
    event.preventDefault()
    this.formTarget.classList.toggle('hidden')
    if (!this.formTarget.classList.contains('hidden')) {
      this.nameInputTarget.focus()
    }
  }

  cancel(event) {
    event.preventDefault()
    this.formTarget.classList.add('hidden')
    this.resetForm()
  }

  resetForm() {
    this.nameInputTarget.value = ''
    this.categoryInputTarget.value = ''
    this.colorInputTarget.value = '#3B82F6'
  }

  async submit(event) {
    event.preventDefault()

    // バリデーション
    if (!this.nameInputTarget.value.trim()) {
      alert('タグ名を入力してください')
      this.nameInputTarget.focus()
      return
    }

    const formData = new FormData()
    formData.append('tag[name]', this.nameInputTarget.value)
    formData.append('tag[category]', this.categoryInputTarget.value)
    formData.append('tag[color]', this.colorInputTarget.value)

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
        const tag = await response.json()
        this.addTagToList(tag)
        this.formTarget.classList.add('hidden')
        this.resetForm()
      } else {
        const data = await response.json()
        alert(data.errors ? data.errors.join('\n') : 'タグの作成に失敗しました')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('タグの作成に失敗しました')
    }
  }

  addTagToList(tag) {
    // "まだタグが登録されていません" のメッセージを削除
    const noTagsMessage = this.tagListTarget.querySelector('p.text-gray-500')
    if (noTagsMessage) {
      noTagsMessage.remove()
    }

    // 新しいタグを追加
    const label = document.createElement('label')
    label.className = 'inline-flex items-center cursor-pointer'

    const checkbox = document.createElement('input')
    checkbox.type = 'checkbox'
    checkbox.name = 'medical_record[tag_ids][]'
    checkbox.value = tag.id
    checkbox.id = `medical_record_tag_${tag.id}`
    checkbox.className = 'sr-only peer'
    checkbox.checked = true  // 新しく作成したタグは自動的に選択状態にする

    const span = document.createElement('span')
    span.className = 'px-3 py-2 rounded-full text-sm font-medium border-2 transition-all peer-checked:border-opacity-100 peer-checked:ring-2 peer-checked:ring-offset-1 border-opacity-30'
    span.style.borderColor = tag.color
    span.style.backgroundColor = `${tag.color}15`
    span.style.color = tag.color
    span.style.setProperty('--tw-ring-color', tag.color)
    span.textContent = tag.name

    label.appendChild(checkbox)
    label.appendChild(span)
    this.tagListTarget.appendChild(label)
  }
}
