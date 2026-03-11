import { Controller } from "@hotwired/stimulus"

// App-wide keyboard handling: prevent Enter from submitting multi-field forms
// to avoid accidental "view jumping" (full page reload) when user hits Enter
// while tabbing through fields. Single-field add-task forms still submit on Enter.
export default class extends Controller {
  connect() {
    this.boundKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown, true)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown, true)
  }

  onKeydown(event) {
    if (event.key !== "Enter") return

    const form = event.target?.closest?.("form[data-no-enter-submit]")
    if (form) {
      event.preventDefault()
      event.stopPropagation()
    }
  }
}
