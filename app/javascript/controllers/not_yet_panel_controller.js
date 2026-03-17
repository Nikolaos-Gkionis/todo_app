import { Controller } from "@hotwired/stimulus"

// Right-hand "Not Yet" panel — slides in from right, with tabs for each page (list)
export default class extends Controller {
  static targets = ["panel", "overlay", "title", "tab", "tabPane"]
  static values = { settingsPath: String, appRootPath: String, openOnLoad: Boolean }

  connect() {
    // Reopen panel after creating a new tab (redirect with ?panel=open)
    if (this.openOnLoadValue) {
      requestAnimationFrame(() => this.open())
    }
    // Switch to tab when dragging todo over it — allows drop on other lists
    this._boundTabDragOver = this.tabDragOver.bind(this)
    document.addEventListener('dragover', this._boundTabDragOver, true)
    if (this.hasTitleTarget) {
      this._boundBlur = this.saveTitleOnBlur.bind(this)
      this._boundKeydown = this.handleTitleKeydown.bind(this)
      this.titleTarget.addEventListener("blur", this._boundBlur)
      this.titleTarget.addEventListener("keydown", this._boundKeydown)
    }
  }

  disconnect() {
    document.removeEventListener('dragover', this._boundTabDragOver, true)
    if (this.hasTitleTarget && this._boundBlur) {
      this.titleTarget.removeEventListener("blur", this._boundBlur)
      this.titleTarget.removeEventListener("keydown", this._boundKeydown)
    }
  }

  // When dragging a todo over an inactive tab, switch to that tab so user can drop
  tabDragOver(e) {
    if (!document.body.classList.contains('is-dragging-todo')) return
    if (!this.hasPanelTarget || !this.panelTarget.classList.contains('not-yet-panel--open')) return
    const tab = e.target.closest('.not-yet-panel__tab')
    if (!tab) return
    const pageId = tab.dataset.pageId
    if (!pageId) return
    const activePane = this.tabPaneTargets.find(p => p.classList.contains('not-yet-panel__tab-pane--active'))
    if (activePane && activePane.dataset.pageId === String(pageId)) return // Already on this tab
    this.showTab(pageId)
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

  // ── Tab actions ──
  switchTab(e) {
    // Don't switch if user clicked delete or is interacting with the label
    if (e.target.closest(".not-yet-panel__tab-action")) return
    const pageId = e.currentTarget.dataset.pageId
    if (!pageId) return
    this.showTab(pageId)
  }

  prevTab() {
    const tabs = this.tabTargets
    if (tabs.length < 2) return
    const activeIdx = tabs.findIndex(t => t.classList.contains("not-yet-panel__tab--active"))
    const nextIdx = activeIdx <= 0 ? tabs.length - 1 : activeIdx - 1
    const pageId = tabs[nextIdx].dataset.pageId
    this.showTab(pageId)
  }

  nextTab() {
    const tabs = this.tabTargets
    if (tabs.length < 2) return
    const activeIdx = tabs.findIndex(t => t.classList.contains("not-yet-panel__tab--active"))
    const nextIdx = activeIdx >= tabs.length - 1 ? 0 : activeIdx + 1
    const pageId = tabs[nextIdx].dataset.pageId
    this.showTab(pageId)
  }

  showTab(pageId) {
    this.tabTargets.forEach(t => {
      t.classList.toggle("not-yet-panel__tab--active", t.dataset.pageId === String(pageId))
    })
    this.tabPaneTargets.forEach(p => {
      p.classList.toggle("not-yet-panel__tab-pane--active", p.dataset.pageId === String(pageId))
    })
  }

  createTab() {
    const dialog = document.getElementById("new-list-dialog")
    if (dialog) dialog.showModal()
  }

  deleteTab(e) {
    e.stopPropagation()
    const pageId = e.currentTarget.dataset.pageId
    if (!pageId || !confirm("Delete this list and all its tasks?")) return
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrf) return
    fetch(`/app/pages/${pageId}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": csrf, "Accept": "text/html" }
    }).then(res => {
      if (res.ok || res.redirected) window.location.href = this.appRootPathValue || "/app"
    })
  }

  saveTabName(e) {
    const label = e.target
    if (!label.classList.contains("not-yet-panel__tab-label") || !label.isContentEditable) return
    const pageId = label.dataset.pageId
    const value = label.textContent.trim()
    const initial = label.dataset.initialName || ""
    if (!pageId || value === initial || value.length === 0) {
      if (value.length === 0) label.textContent = initial
      return
    }
    label.dataset.initialName = value
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrf) return
    fetch(`/app/pages/${pageId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrf },
      body: JSON.stringify({ page: { name: value } })
    }).then(r => r.json()).then(data => {
      if (data.status === "success") return
      label.textContent = initial
      label.dataset.initialName = initial
    }).catch(() => {
      label.textContent = initial
      label.dataset.initialName = initial
    })
  }

  tabNameKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      e.target.blur()
    }
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
    // Don't close when clicking inside an open dialog (e.g. new-list-dialog)
    if (event.target.closest?.("dialog[open]")) return
    if (this.hasOverlayTarget && event.target === this.overlayTarget) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.hasPanelTarget && this.panelTarget.classList.contains("not-yet-panel--open")) {
      this.close()
    }
  }

  /**
   * Keyboard navigation when panel is open: Arrow Up/Down move between tasks,
   * Page Up/Down switch between lists (tabs).
   */
  handlePanelKeydown(event) {
    if (!this.hasPanelTarget || !this.panelTarget.classList.contains("not-yet-panel--open")) return

    // Don't intercept when user is typing in an input or contenteditable
    const target = event.target
    if (target.matches("input, textarea, select")) return
    if (target.closest("[contenteditable='true']")) return

    const activePane = this.tabPaneTargets.find(p => p.classList.contains("not-yet-panel__tab-pane--active"))
    if (!activePane) return

    if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      event.preventDefault()
      this.focusAdjacentTask(activePane, event.key === "ArrowDown")
    } else if (event.key === "PageUp" || event.key === "PageDown") {
      if (this.tabTargets.length < 2) return
      event.preventDefault()
      if (event.key === "PageUp") {
        this.prevTab()
      } else {
        this.nextTab()
      }
      this.focusFirstTaskInActivePane()
    }
  }

  /** Get ordered list of focusable elements for task navigation (checkboxes + add input) */
  getTaskFocusables(activePane) {
    const items = []
    activePane.querySelectorAll(".todo-item").forEach((el) => {
      const focusable = el.querySelector(".todo-checkbox-box") || el.querySelector('[tabindex="0"]')
      if (focusable) items.push(focusable)
    })
    const addInput = activePane.querySelector(".todo-input")
    if (addInput) items.push(addInput)
    return items
  }

  /** Focus previous or next task in the active pane */
  focusAdjacentTask(activePane, next) {
    const focusables = this.getTaskFocusables(activePane)
    if (focusables.length === 0) return

    const current = document.activeElement
    const idx = focusables.indexOf(current)
    const newIdx = next ? (idx < 0 ? 0 : Math.min(idx + 1, focusables.length - 1)) : (idx <= 0 ? focusables.length - 1 : idx - 1)
    focusables[newIdx].focus()
  }

  /** Focus the first task (or add input) in the active pane after switching tabs */
  focusFirstTaskInActivePane() {
    const activePane = this.tabPaneTargets.find(p => p.classList.contains("not-yet-panel__tab-pane--active"))
    if (!activePane) return
    const focusables = this.getTaskFocusables(activePane)
    if (focusables.length > 0) focusables[0].focus()
  }
}
