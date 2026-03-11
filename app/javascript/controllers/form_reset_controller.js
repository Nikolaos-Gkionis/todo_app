import { Controller } from "@hotwired/stimulus"

// Triggers form reset + focus when a turbo stream injects this controller.
// The turbo stream sends the form ID via data-form-reset-form-id-value.
// Scripts in turbo stream update don't reliably execute; Stimulus connect() does.
export default class extends Controller {
  static values = { formId: String }

  connect() {
    const formId = this.formIdValue
    if (!formId) return

    // Defer to next tick so turbo stream DOM updates are complete
    requestAnimationFrame(() => {
      const form = document.getElementById(formId)
      if (!form) return

      form.reset()
      const input = form.querySelector("input.todo-input")
      if (input) {
        input.focus({ preventScroll: true })
      }
    })
  }
}
