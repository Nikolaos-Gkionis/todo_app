import { Controller } from "@hotwired/stimulus"

// Handles Add Task forms: prevents double-submit, ensures Enter works correctly.
// Attach to single-line "add task" forms (dashboard week columns, Not Yet panel).
export default class extends Controller {
  static values = { preventDoubleSubmit: { type: Boolean, default: true } }

  connect() {
    this.submitting = false
  }

  // Allow Enter to submit; ensure we don't have conflicting handlers.
  // For single-field forms, default behavior is fine — we just avoid double-submit.
  onKeydown(event) {
    if (event.key !== "Enter") return
    // Let Enter submit the form (default). Only prevent if we're double-submitting.
    if (this.preventDoubleSubmitValue && this.submitting) {
      event.preventDefault()
    }
  }

  onSubmit() {
    if (this.preventDoubleSubmitValue) {
      this.submitting = true
      // Re-enable after a short delay (turbo stream will reset form)
      setTimeout(() => { this.submitting = false }, 1500)
    }
  }
}
