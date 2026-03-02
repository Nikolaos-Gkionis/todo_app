import { Controller } from "@hotwired/stimulus"

// Displays device date/time - updates every second for time
// Use data-controller="device-datetime" data-device-datetime-format-value="long"
// Targets: date (for date), time (for time)
export default class extends Controller {
  static targets = ["date", "time"]
  static values = {
    format: { type: String, default: "long" } // "long" | "short"
  }

  connect() {
    this.tick()
    this.intervalId = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId)
  }

  tick() {
    const now = new Date()

    if (this.hasDateTarget) {
      this.dateTarget.textContent = this.formatDate(now)
    }
    if (this.hasTimeTarget) {
      this.timeTarget.textContent = this.formatTime(now)
    }
  }

  formatDate(d) {
    const opts = this.formatValue === "short"
      ? { weekday: "short", month: "short", day: "numeric", year: "numeric" }
      : { weekday: "long", month: "long", day: "numeric", year: "numeric" }
    return d.toLocaleDateString(undefined, opts)
  }

  formatTime(d) {
    return d.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", second: "2-digit" })
  }
}
