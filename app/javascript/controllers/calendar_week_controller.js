import { Controller } from "@hotwired/stimulus"

// Scrolls to today's column on mobile when calendar week loads
// data-controller="calendar-week" data-calendar-week-today-value="3"
// (today's column index 0–6, with 0=Monday)
export default class extends Controller {
  static values = {
    today: Number // 0-6, Monday=0
  }

  connect() {
    // On mobile, scroll the week strip so today is in view/centered
    if (window.matchMedia("(max-width: 768px)").matches && this.hasTodayValue) {
      this.scrollToToday()
    }
  }

  scrollToToday() {
    const columns = this.element.querySelectorAll("[data-calendar-day]")
    const todayCol = columns[this.todayValue]
    if (todayCol) {
      todayCol.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
    }
  }
}
