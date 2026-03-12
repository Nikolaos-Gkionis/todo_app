import { Controller } from "@hotwired/stimulus"

/**
 * Inline edit: tap title to place cursor at end and edit. Blur or Enter saves. Escape cancels.
 * Snappy: no navigation, immediate focus at end.
 */
export default class extends Controller {
  static targets = ["display", "input", "form", "editContainer"]

  connect() {
    this.originalTitle = this.displayTarget.textContent.trim()
  }

  startEdit() {
    const input = this.inputTarget
    const display = this.displayTarget
    const container = this.hasEditContainerTarget ? this.editContainerTarget : input.parentElement
    const form = this.formTarget
    this.originalTitle = display.textContent.trim()
    display.style.display = "none"
    form.style.display = "flex"
    form.style.flex = "1"
    form.style.minWidth = "0"
    container.style.display = ""
    input.value = this.originalTitle
    input.focus()
    input.setSelectionRange(input.value.length, input.value.length)
    input.addEventListener("blur", this.boundBlur = () => this.commitEdit())
    input.addEventListener("keydown", this.boundKeydown = (e) => this.handleKeydown(e))
  }

  handleKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.commitEdit()
    } else if (e.key === "Escape") {
      this.cancelEdit()
    }
  }

  commitEdit() {
    this.removeListeners()
    const input = this.inputTarget
    const display = this.displayTarget
    const form = this.formTarget
    const container = this.hasEditContainerTarget ? this.editContainerTarget : input.parentElement
    const newTitle = input.value.trim()
    if (newTitle && newTitle !== this.originalTitle) {
      form.requestSubmit()
    } else {
      form.style.display = "none"
      container.style.display = "none"
      display.style.display = ""
    }
  }

  cancelEdit() {
    this.removeListeners()
    this.inputTarget.value = this.originalTitle
    this.formTarget.style.display = "none"
    if (this.hasEditContainerTarget) {
      this.editContainerTarget.style.display = "none"
    }
    this.displayTarget.style.display = ""
    this.inputTarget.blur()
  }

  removeListeners() {
    this.inputTarget.removeEventListener("blur", this.boundBlur)
    this.inputTarget.removeEventListener("keydown", this.boundKeydown)
  }
}
