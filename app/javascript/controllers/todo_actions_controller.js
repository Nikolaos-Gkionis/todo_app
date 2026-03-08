import { Controller } from "@hotwired/stimulus"

/**
 * Todo row: on mobile, single tap opens options modal, double tap marks complete.
 * Desktop: unchanged (hover shows toolbar, click title toggles complete).
 */
export default class extends Controller {
  static targets = ["titleBtn", "completeForm", "optionsModal"]

  static values = {
    todoId: String
  }

  connect() {
    this.lastTapAt = 0
    this.tapDelay = 350
    this.isMobile = () => window.matchMedia("(max-width: 768px)").matches
  }

  onTitleClick(event) {
    if (!this.isMobile()) return
    event.preventDefault()
    const now = Date.now()
    if (now - this.lastTapAt < this.tapDelay) {
      this.lastTapAt = 0
      this.completeFormTarget.requestSubmit()
      return
    }
    this.lastTapAt = now
    const modal = this.optionsModalTarget
    setTimeout(() => {
      if (this.lastTapAt === now) {
        modal.showModal()
      }
    }, this.tapDelay)
  }
}
