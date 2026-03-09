import { Controller } from "@hotwired/stimulus"

// Right-hand "Not Yet" panel — slides in from right (legal-changes: Future Tasks)
export default class extends Controller {
  static targets = ["panel", "overlay", "title"]
  static values = { settingsPath: String }

  connect() {
    if (this.hasTitleTarget) {
      this._boundBlur = this.saveTitleOnBlur.bind(this)
      this._boundKeydown = this.handleTitleKeydown.bind(this)
      this.titleTarget.addEventListener("blur", this._boundBlur)
      this.titleTarget.addEventListener("keydown", this._boundKeydown)
    }
  }

  disconnect() {
    if (this.hasTitleTarget && this._boundBlur) {
      this.titleTarget.removeEventListener("blur", this._boundBlur)
      this.titleTarget.removeEventListener("keydown", this._boundKeydown)
    }
  }

  handleTitleKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.titleTarget.blur()
    }
  }

  saveTitleOnBlur() {
    const value = this.titleTarget.textContent.trim() || "Not Yet"
    const initial = this.titleTarget.dataset.initialValue || "Not Yet"
    if (value === initial) return

    this.titleTarget.dataset.initialValue = value
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrf) return

    const path = this.settingsPathValue || "/app/settings"
    fetch(path, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrf },
      body: JSON.stringify({ user: { not_yet_panel_title: value } })
    }).then(r => r.json()).then(data => {
      if (data.status === "success") return
      this.titleTarget.textContent = initial
      this.titleTarget.dataset.initialValue = initial
    }).catch(() => {
      this.titleTarget.textContent = initial
      this.titleTarget.dataset.initialValue = initial
    })
  }

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
