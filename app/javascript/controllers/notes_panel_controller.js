import { Controller } from "@hotwired/stimulus"

// Manages the notes side-panel: open/close, rich-text toolbar, auto-save.
export default class extends Controller {
  static targets = [
    "drawer", "overlay", "title", "date",
    "editor", "subtaskList", "savedIndicator",
    "linkModal", "linkInput",
    "imageFileInput"
  ]

  connect() {
    this.currentTodoId = null
    this.saveTimer = null
  }

  disconnect() {
    if (this.saveTimer) clearTimeout(this.saveTimer)
  }

  // ── Open the panel for a specific todo (called via window event) ──
  open(event) {
    const { id, title, notes } = event.detail || {}
    if (!id) return

    this.currentTodoId = id

    if (this.hasTitleTarget) this.titleTarget.textContent = title || "Untitled"

    if (this.hasDateTarget) {
      this.dateTarget.textContent = new Date().toLocaleDateString("en-US", {
        month: "short", day: "numeric", year: "numeric"
      }).toUpperCase()
    }

    // Parse notes: split editor content from subtask data
    const raw = notes || ""
    const subtaskMatch = raw.match(/<!--subtasks:(.*?)-->/)
    const editorContent = raw.replace(/<!--subtasks:.*?-->/, "")

    if (this.hasEditorTarget) {
      this.editorTarget.innerHTML = editorContent
    }

    this.loadSubtasks(subtaskMatch ? subtaskMatch[1] : null)

    if (this.hasDrawerTarget) this.drawerTarget.classList.add("side-drawer--open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "block"
  }

  // ── Close the panel ──
  close() {
    this.saveNotes()
    if (this.hasDrawerTarget) this.drawerTarget.classList.remove("side-drawer--open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
    this.currentTodoId = null
  }

  closeOnOverlay(event) {
    if (this.hasOverlayTarget && event.target === this.overlayTarget) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.hasDrawerTarget &&
        this.drawerTarget.classList.contains("side-drawer--open")) {
      this.close()
    }
  }

  // ── Rich text commands ──
  bold() {
    document.execCommand("bold", false, null)
    this.editorTarget.focus()
    this.scheduleSave()
  }

  italic() {
    document.execCommand("italic", false, null)
    this.editorTarget.focus()
    this.scheduleSave()
  }

  insertLink() {
    // Save the current selection so we can restore it after the modal
    const sel = window.getSelection()
    this.savedRange = sel.rangeCount > 0 ? sel.getRangeAt(0) : null

    if (this.hasLinkInputTarget) this.linkInputTarget.value = ""
    if (this.hasLinkModalTarget) {
      this.linkModalTarget.style.display = "flex"
      this.linkInputTarget.focus()
    }
  }

  confirmLink() {
    const url = this.hasLinkInputTarget ? this.linkInputTarget.value.trim() : ""
    this.closeLinkModal()

    if (!url) return

    // Restore the selection that was active before the modal opened
    if (this.savedRange) {
      const sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(this.savedRange)
    }

    document.execCommand("createLink", false, url)
    this.editorTarget.focus()
    this.scheduleSave()
  }

  closeLinkModal() {
    if (this.hasLinkModalTarget) this.linkModalTarget.style.display = "none"
  }

  linkInputKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.confirmLink()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.closeLinkModal()
    }
  }

  insertBullet() {
    document.execCommand("insertUnorderedList", false, null)
    this.editorTarget.focus()
    this.scheduleSave()
  }

  insertImage() {
    // Save selection so we can restore it after picking a file
    const sel = window.getSelection()
    this.savedRange = sel.rangeCount > 0 ? sel.getRangeAt(0) : null

    // Fire the native file picker (desktop: file explorer, mobile: camera/gallery)
    if (this.hasImageFileInputTarget) {
      this.imageFileInputTarget.value = ""
      this.imageFileInputTarget.click()
    }
  }

  onImageFileSelected(event) {
    const file = event.target.files?.[0]
    if (!file || !file.type.startsWith("image/")) return

    // Cap at ~2MB to avoid huge base64 in notes
    if (file.size > 2 * 1024 * 1024) {
      alert("Image too large. Please choose an image under 2MB.")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      const dataUrl = e.target?.result
      if (!dataUrl) return

      if (this.savedRange && this.hasEditorTarget) {
        const sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange(this.savedRange)
      }

      document.execCommand("insertImage", false, dataUrl)
      this.editorTarget.focus()
      this.scheduleSave()
    }
    reader.readAsDataURL(file)
  }

  // ── Subtasks (checklists) ──
  addSubtask(afterElement) {
    if (!this.hasSubtaskListTarget) return

    const item = document.createElement("div")
    item.classList.add("notes-subtask")
    item.innerHTML = `
      <label class="notes-subtask__label">
        <input type="checkbox" class="notes-subtask__checkbox" data-action="change->notes-panel#scheduleSave">
        <span class="notes-subtask__text" contenteditable="true" data-action="input->notes-panel#scheduleSave keydown->notes-panel#subtaskKeydown" data-placeholder="New subtask..."></span>
      </label>
      <button type="button" class="notes-subtask__delete" data-action="click->notes-panel#removeSubtask" aria-label="Remove subtask">&times;</button>
    `

    // Insert after the current subtask if one was provided, otherwise append
    if (afterElement instanceof HTMLElement && afterElement.closest(".notes-subtask")) {
      const currentSubtask = afterElement.closest(".notes-subtask")
      currentSubtask.after(item)
    } else {
      this.subtaskListTarget.appendChild(item)
    }

    const textSpan = item.querySelector(".notes-subtask__text")
    if (textSpan) textSpan.focus()
  }

  // Intercept Enter inside subtask text to create a new subtask on the next line
  subtaskKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.addSubtask(event.currentTarget)
      this.scheduleSave()
    }
  }

  removeSubtask(event) {
    const subtaskEl = event.currentTarget.closest(".notes-subtask")
    if (subtaskEl) subtaskEl.remove()
    this.scheduleSave()
  }

  onEditorInput() {
    this.scheduleSave()
  }

  // ── Save logic ──
  scheduleSave() {
    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.saveNotes(), 800)
  }

  saveNotes() {
    if (!this.currentTodoId) return

    const editorHTML = this.hasEditorTarget ? this.editorTarget.innerHTML : ""
    const subtasks = this.gatherSubtasks()

    const subtaskMarker = subtasks.length > 0
      ? `<!--subtasks:${JSON.stringify(subtasks)}-->`
      : ""
    const fullNotes = editorHTML + subtaskMarker

    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (!csrf) return

    fetch(`/app/todos/${this.currentTodoId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrf.content
      },
      body: JSON.stringify({ todo: { notes: fullNotes } })
    }).then(() => {
      // Sync data attribute on the source button
      const btn = document.getElementById(`notes-btn-${this.currentTodoId}`)
      if (btn) {
        btn.dataset.todoNotes = fullNotes
        const hasContent = editorHTML.replace(/<[^>]*>/g, "").trim().length > 0 || subtasks.length > 0
        btn.classList.toggle("todo-item__notes-btn--active", hasContent)
      }
      this.updateSavedIndicator()
    }).catch(err => console.error("Notes save failed:", err))
  }

  updateSavedIndicator() {
    if (!this.hasSavedIndicatorTarget) return
    const time = new Date().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })
    this.savedIndicatorTarget.textContent = `Last saved Today ${time}`
    this.savedIndicatorTarget.style.opacity = "1"
  }

  gatherSubtasks() {
    if (!this.hasSubtaskListTarget) return []
    return Array.from(this.subtaskListTarget.querySelectorAll(".notes-subtask")).map(item => ({
      text: (item.querySelector(".notes-subtask__text")?.textContent || "").trim(),
      done: item.querySelector(".notes-subtask__checkbox")?.checked || false
    })).filter(s => s.text.length > 0)
  }

  loadSubtasks(json) {
    if (!this.hasSubtaskListTarget) return
    this.subtaskListTarget.innerHTML = ""
    if (!json) return

    try {
      JSON.parse(json).forEach(st => {
        const item = document.createElement("div")
        item.classList.add("notes-subtask")
        item.innerHTML = `
          <label class="notes-subtask__label">
            <input type="checkbox" class="notes-subtask__checkbox" ${st.done ? "checked" : ""} data-action="change->notes-panel#scheduleSave">
            <span class="notes-subtask__text" contenteditable="true" data-action="input->notes-panel#scheduleSave keydown->notes-panel#subtaskKeydown">${this.escapeHTML(st.text)}</span>
          </label>
          <button type="button" class="notes-subtask__delete" data-action="click->notes-panel#removeSubtask" aria-label="Remove subtask">&times;</button>
        `
        this.subtaskListTarget.appendChild(item)
      })
    } catch (e) { /* ignore malformed data */ }
  }

  escapeHTML(str) {
    const d = document.createElement("div")
    d.textContent = str
    return d.innerHTML
  }
}
