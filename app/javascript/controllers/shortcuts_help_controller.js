import { Controller } from "@hotwired/stimulus"

/**
 * Shows the keyboard shortcuts help modal when the user presses ?.
 * Listens for show-shortcuts-help event from keyboard_shortcuts_controller.
 */
export default class extends Controller {
  static targets = ["modal", "overlay"]

  connect() {
    this.boundShow = this.show.bind(this)
    this.boundClose = this.close.bind(this)
    this.boundKeydown = this.handleKeydown.bind(this)
    this.boundOverlayClick = this.closeOnOverlayClick.bind(this)

    window.addEventListener("show-shortcuts-help", this.boundShow)
  }

  disconnect() {
    window.removeEventListener("show-shortcuts-help", this.boundShow)
    document.removeEventListener("keydown", this.boundKeydown)
    if (this.hasOverlayTarget) {
      this.overlayTarget.removeEventListener("click", this.boundOverlayClick)
    }
  }

  show() {
    if (!this.hasModalTarget) return
    this.previousFocus = document.activeElement
    this.modalTarget.classList.add("show")
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.boundKeydown)
    if (this.hasOverlayTarget) {
      this.overlayTarget.addEventListener("click", this.boundOverlayClick)
    }
    // Focus the close button for accessibility
    const closeBtn = this.modalTarget.querySelector(".shortcuts-help__close")
    if (closeBtn) closeBtn.focus()
  }

  close() {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.remove("show")
    this.modalTarget.setAttribute("aria-hidden", "true")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundKeydown)
    if (this.hasOverlayTarget) {
      this.overlayTarget.removeEventListener("click", this.boundOverlayClick)
    }
    if (this.previousFocus && this.previousFocus.focus) {
      this.previousFocus.focus()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
    // Focus trap: Tab cycles within modal
    if (event.key !== "Tab") return
    const focusables = this.modalTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const focusableList = [].slice.call(focusables).filter((el) => el.offsetParent !== null)
    const first = focusableList[0]
    const last = focusableList[focusableList.length - 1]
    if (event.shiftKey) {
      if (document.activeElement === first) {
        event.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }
  }

  closeOnOverlayClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
