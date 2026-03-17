import { Controller } from "@hotwired/stimulus"

/**
 * Global keyboard shortcuts for the app (dashboard and authenticated pages).
 * Only fires when NOT typing in input, textarea, or contenteditable.
 * Avoids browser shortcut conflicts; does not override Ctrl/Cmd+C, V, etc.
 */
export default class extends Controller {
  static values = {
    appRootPath: { type: String, default: "/app" }
  }

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown, true)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown, true)
  }

  /**
   * Returns true if we should ignore this keydown (e.g. user is typing in an input)
   */
  shouldIgnore(event) {
    // Ignore when typing in editable fields
    const target = event.target
    if (target.matches("input, textarea, select")) return true
    if (target.closest("[contenteditable='true']")) return true

    // Ignore on marketing pages
    if (document.body.dataset.marketingPage === "true") return true

    // When a modal/dialog is open, only Escape is handled (by other controllers)
    if (document.querySelector("dialog[open]")) return true
    if (document.querySelector(".logout-modal.show")) return true
    if (document.querySelector(".confirm-modal.show")) return true
    if (document.querySelector(".shortcuts-help.show")) return true

    return false
  }

  handleKeydown(event) {
    if (this.shouldIgnore(event)) return

    // Route by key (Escape is handled by panel/modal controllers)
    switch (event.key) {
      case "n":
        if (event.shiftKey) {
          this.createNewList(event)
        } else {
          this.focusNewTask(event)
        }
        break
      case "y":
        this.toggleNotYetPanel(event)
        break
      case "s":
        this.openSettings(event)
        break
      case "t":
        this.goToToday(event)
        break
      case "ArrowLeft":
        if (!document.querySelector(".not-yet-panel--open")) {
          event.shiftKey ? this.prevWeek(event) : this.prevDay(event)
        }
        break
      case "ArrowRight":
        if (!document.querySelector(".not-yet-panel--open")) {
          event.shiftKey ? this.nextWeek(event) : this.nextDay(event)
        }
        break
      case "c":
        this.openCalendar(event)
        break
      case "x":
        this.toggleCompleted(event)
        break
      case "?":
        this.showHelp(event)
        break
    }
  }

  focusNewTask(event) {
    event.preventDefault()
    // Prefer today column's input; fallback to first visible .todo-input
    const todayInput = document.querySelector(".week-col--today .todo-input")
    const firstInput = document.querySelector(".todo-input")
    const input = todayInput || firstInput
    if (input) {
      input.focus()
      input.select?.()
    }
  }

  toggleNotYetPanel(event) {
    event.preventDefault()
    window.dispatchEvent(new CustomEvent("toggle-not-yet-panel"))
  }

  openSettings(event) {
    event.preventDefault()
    window.dispatchEvent(new CustomEvent("open-settings-panel"))
  }

  goToToday(event) {
    event.preventDefault()
    const path = this.appRootPathValue || "/app"
    if (typeof Turbo !== "undefined") {
      Turbo.visit(path)
    } else {
      window.location.href = path
    }
  }

  prevDay(event) {
    const link = document.querySelector('a[aria-label="Previous day"]')
    if (link) {
      event.preventDefault()
      link.click()
    }
  }

  nextDay(event) {
    const link = document.querySelector('a[aria-label="Next day"]')
    if (link) {
      event.preventDefault()
      link.click()
    }
  }

  prevWeek(event) {
    const link = document.querySelector('a[aria-label="Previous week"]')
    if (link) {
      event.preventDefault()
      link.click()
    }
  }

  nextWeek(event) {
    const link = document.querySelector('a[aria-label="Next week"]')
    if (link) {
      event.preventDefault()
      link.click()
    }
  }

  openCalendar(event) {
    const btn = document.querySelector(".calendar-picker__trigger")
    if (btn) {
      event.preventDefault()
      btn.click()
    }
  }

  createNewList(event) {
    // Only when Not Yet panel is open
    const panel = document.querySelector(".not-yet-panel--open")
    if (!panel) return

    event.preventDefault()
    const createBtn = document.querySelector("[data-action*='createTab']")
    if (createBtn) createBtn.click()
  }

  toggleCompleted(event) {
    event.preventDefault()
    const show = localStorage.getItem("showCompleted") !== "false"
    const newShow = !show

    document.querySelectorAll(".todo-item--done").forEach((el) => {
      el.style.display = newShow ? "" : "none"
    })
    localStorage.setItem("showCompleted", newShow)

    // Sync Settings UI
    const showBtn = document.getElementById("pref-show-completed")
    const hideBtn = document.getElementById("pref-hide-completed")
    if (showBtn) showBtn.classList.toggle("pref-toggle-btn--active", newShow)
    if (hideBtn) hideBtn.classList.toggle("pref-toggle-btn--active", !newShow)
  }

  showHelp(event) {
    event.preventDefault()
    window.dispatchEvent(new CustomEvent("show-shortcuts-help"))
  }
}
