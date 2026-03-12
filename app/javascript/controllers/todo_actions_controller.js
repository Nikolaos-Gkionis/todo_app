import { Controller } from "@hotwired/stimulus"

/**
 * Todo row: checkbox toggles complete, title links to edit, menu (⋯) opens options modal.
 * Desktop: hover shows toolbar; checkbox = complete, title = edit, ⋯ = modal.
 * Mobile: same behavior; menu button provides access to toolbar options.
 */
export default class extends Controller {
  static targets = ["completeForm", "optionsModal"]

  static values = {
    todoId: String
  }

  openModal() {
    this.optionsModalTarget.showModal()
  }
}
