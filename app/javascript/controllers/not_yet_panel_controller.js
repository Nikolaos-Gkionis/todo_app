import { Controller } from "@hotwired/stimulus"

// Right-hand "Not Yet" panel — slides in from right (legal-changes: Future Tasks)
export default class extends Controller {
  static targets = ["panel", "overlay"]

  toggle() {
    const isOpen = this.hasPanelTarget && this.panelTarget.classList.contains("not-yet-panel--open")
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.hasPanelTarget) this.panelTarget.classList.add("not-yet-panel--open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "block"
    document.body.style.overflow = "hidden"
  }

  close() {
    if (this.hasPanelTarget) this.panelTarget.classList.remove("not-yet-panel--open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
    document.body.style.overflow = ""
  }

  closeOnOverlay(event) {
    if (this.hasOverlayTarget && event.target === this.overlayTarget) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.hasPanelTarget && this.panelTarget.classList.contains("not-yet-panel--open")) {
      this.close()
    }
  }
}
