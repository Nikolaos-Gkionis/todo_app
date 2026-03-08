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
  }

  open() {
    this.displayedMonth = this.initialMonth()
    this.render()
    this.modalTarget.showModal()
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

      html += '<a href="' + url + '" class="' + cls + '" data-turbo-frame="_top">' + d + '</a>'
    }

    html += "</div>"
    this.gridTarget.innerHTML = html
  }
}
