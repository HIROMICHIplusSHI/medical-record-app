import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    options: Object
  }

  connect() {
    const defaultOptions = {
      create: false,
      sortField: {
        field: "text",
        direction: "asc"
      },
      maxOptions: 200,
      // iPad/タッチデバイス最適化
      controlInput: '<input type="text" autocomplete="off" size="1" class="text-xl">',
      dropdownParent: 'body',
      render: {
        option: (data, escape) => {
          return `<div class="option text-xl py-3 px-4">${escape(data.text)}</div>`;
        },
        item: (data, escape) => {
          return `<div class="item text-xl">${escape(data.text)}</div>`;
        }
      }
    }

    // カスタムオプションをマージ
    const options = { ...defaultOptions, ...this.optionsValue }

    this.tomSelect = new TomSelect(this.element, options)
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
