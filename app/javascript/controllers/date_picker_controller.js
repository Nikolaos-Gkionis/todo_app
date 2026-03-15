import { Controller } from "@hotwired/stimulus"

/**
 * Date picker modal: opens a month grid for date selection.
 * - "Today" link navigates to current day
 * - Clicking a date navigates to that day
 * - Month nav changes displayed month (no navigation)
 */
export default class extends Controller {
  static targets = ["modal", "grid", "monthLabel"]
  static values = {
    basePath: { type: String, default: "/app" },
    startDate: { type: String }
  }

  connect() {
    this.displayedMonth = this.initialMonth()
    this.boundKeydown = this.handleKeydown.bind(this)
    this.modalTarget.addEventListener("close", this.onModalClose.bind(this))
  }

  syncThemeOnClose() {
    this.modalTarget.classList.remove("theme-dark")
  }

  onModalClose() {
    this.syncThemeOnClose()
    document.removeEventListener("keydown", this.boundKeydown)
  }

  open() {
    this.displayedMonth = this.initialMonth()
    this.render()
    // Apply dark theme class so styles work when dialog is in browser top layer
    if (document.body.classList.contains("theme-dark")) {
      this.modalTarget.classList.add("theme-dark")
    } else {
      this.modalTarget.classList.remove("theme-dark")
    }
    this.modalTarget.showModal()
    document.addEventListener("keydown", this.boundKeydown)
    this.focusInitialDate()
  }

  /** Focus the selected date or today when modal opens */
  focusInitialDate() {
    let dateStr = null
    if (this.hasStartDateValue && this.startDateValue) {
      dateStr = this.startDateValue
    } else {
      dateStr = this.toDateString(new Date())
    }
    const link = this.gridTarget?.querySelector('.calendar-modal__day[data-date="' + dateStr + '"]')
    if (link) link.focus()
  }

  /** Handle arrow keys, Enter, Space, PageUp/PageDown for keyboard navigation */
  handleKeydown(event) {
    if (!this.modalTarget.open) return

    const target = event.target
    const isDayLink = target?.classList?.contains?.("calendar-modal__day") && !target.classList.contains("calendar-modal__day--empty")

    // Arrow keys and Enter/Space only when focus is on a day cell
    if (isDayLink) {
      const dateStr = target.getAttribute("data-date")
      if (dateStr && (event.key === "ArrowLeft" || event.key === "ArrowRight" || event.key === "ArrowUp" || event.key === "ArrowDown")) {
        event.preventDefault()
        const nextLink = this.findAdjacentDayLink(dateStr, event.key)
        if (nextLink) nextLink.focus()
        return
      }
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault()
        target.click()
        return
      }
    }

    // Page Up/Down: prev/next month (work from anywhere in modal)
    if (event.key === "PageUp") {
      event.preventDefault()
      this.monthPrev(event)
      this.focusFirstDayOfMonth()
      return
    }
    if (event.key === "PageDown") {
      event.preventDefault()
      this.monthNext(event)
      this.focusFirstDayOfMonth()
      return
    }
  }

  /** Find the day link adjacent to the given date in the specified direction */
  findAdjacentDayLink(dateStr, direction) {
    const parts = dateStr.split("-").map(Number)
    if (parts.length !== 3) return null
    let d = new Date(parts[0], parts[1] - 1, parts[2])
    const delta = direction === "ArrowLeft" ? -1 : direction === "ArrowRight" ? 1 : direction === "ArrowUp" ? -7 : 7
    d.setDate(d.getDate() + delta)
    const nextStr = this.toDateString(d)
    const link = this.gridTarget?.querySelector('.calendar-modal__day[data-date="' + nextStr + '"]')
    if (link) return link
    // Date may be in another month; switch displayed month and re-render
    this.displayedMonth = new Date(d.getFullYear(), d.getMonth(), 1)
    this.render()
    const newLink = this.gridTarget?.querySelector('.calendar-modal__day[data-date="' + nextStr + '"]')
    if (newLink) return newLink
    return null
  }

  /** Focus the first day of the currently displayed month */
  focusFirstDayOfMonth() {
    const year = this.displayedMonth.getFullYear()
    const month = this.displayedMonth.getMonth()
    const firstStr = this.toDateString(new Date(year, month, 1))
    const link = this.gridTarget?.querySelector('.calendar-modal__day[data-date="' + firstStr + '"]')
    if (link) link.focus()
  }

  monthPrev(event) {
    event.preventDefault()
    const d = new Date(this.displayedMonth.getFullYear(), this.displayedMonth.getMonth() - 1, 1)
    this.displayedMonth = d
    this.render()
  }

  monthNext(event) {
    event.preventDefault()
    const d = new Date(this.displayedMonth.getFullYear(), this.displayedMonth.getMonth() + 1, 1)
    this.displayedMonth = d
    this.render()
  }

  initialMonth() {
    if (this.hasStartDateValue && this.startDateValue) {
      const parts = this.startDateValue.split("-").map(Number)
      if (parts.length === 3) {
        return new Date(parts[0], parts[1] - 1, 1)
      }
    }
    const now = new Date()
    return new Date(now.getFullYear(), now.getMonth(), 1)
  }

  toDateString(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  sameDay(a, b) {
    if (!a || !b) return false
    return a.getFullYear() === b.getFullYear() &&
           a.getMonth() === b.getMonth() &&
           a.getDate() === b.getDate()
  }

  render() {
    if (!this.hasGridTarget) return

    const year = this.displayedMonth.getFullYear()
    const month = this.displayedMonth.getMonth()
    const today = new Date()

    const monthNames = ["January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"]
    if (this.hasMonthLabelTarget) {
      this.monthLabelTarget.textContent = monthNames[month] + " " + year
    }

    let startDateObj = null
    if (this.hasStartDateValue && this.startDateValue) {
      const parts = this.startDateValue.split("-").map(Number)
      if (parts.length === 3) {
        startDateObj = new Date(parts[0], parts[1] - 1, parts[2])
      }
    }

    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const startPad = firstDay.getDay()
    const daysInMonth = lastDay.getDate()

    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    let html = '<div class="calendar-modal__header-row">'
    dayNames.forEach(function(name) {
      html += '<span class="calendar-modal__weekday">' + name + '</span>'
    })
    html += "</div><div class=\"calendar-modal__grid-body\">"

    for (let i = 0; i < startPad; i++) {
      html += '<span class="calendar-modal__day calendar-modal__day--empty"></span>'
    }

    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, month, d)
      const dateStr = this.toDateString(date)
      const url = this.basePathValue + "?start_date=" + dateStr
      const isToday = this.sameDay(date, today)
      const isSelected = startDateObj && this.sameDay(date, startDateObj)

      let cls = "calendar-modal__day"
      if (isToday) cls += " calendar-modal__day--today"
      if (isSelected) cls += " calendar-modal__day--selected"

      html += '<a href="' + url + '" class="' + cls + '" data-date="' + dateStr + '" data-turbo-frame="_top">' + d + '</a>'
    }

    html += "</div>"
    this.gridTarget.innerHTML = html
  }
}
