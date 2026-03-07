import { Controller } from "@hotwired/stimulus"

/**
 * Pomodoro timer: 15/25/45 min presets, play/pause, countdown.
 * On complete: shows "Well done!" modal and plays a short success sound.
 */
export default class extends Controller {
  static targets = ["display", "playBtn", "pauseBtn"]
  static values = { duration: { type: Number, default: 25 } }

  connect() {
    this.secondsRemaining = this.durationValue * 60
    this.intervalId = null
    this.isPaused = true
    this.updateDisplay()
  }

  disconnect() {
    this.stop()
  }

  /** Set duration (minutes) and reset timer */
  setDuration(event) {
    const mins = parseInt(event.currentTarget.dataset.pomodoroMinutesParam, 10)
    if (Number.isNaN(mins)) return
    this.durationValue = mins
    this.stop()
    this.secondsRemaining = mins * 60
    this.isPaused = true
    this.updateDisplay()
    this.updatePlayPauseButtons()
    // Update active duration button
    this.element.querySelectorAll(".pomodoro__duration-btn").forEach((btn) => {
      btn.classList.toggle(
        "pomodoro__duration-btn--active",
        parseInt(btn.dataset.pomodoroMinutesParam, 10) === mins
      )
    })
  }

  toggle() {
    if (this.intervalId) {
      this.pause()
    } else {
      this.start()
    }
  }

  start() {
    if (this.secondsRemaining <= 0) return
    this.isPaused = false
    this.intervalId = setInterval(() => this.tick(), 1000)
    this.updatePlayPauseButtons()
  }

  pause() {
    this.isPaused = true
    this.stop()
    this.updatePlayPauseButtons()
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  tick() {
    this.secondsRemaining -= 1
    this.updateDisplay()
    if (this.secondsRemaining <= 0) {
      this.stop()
      this.onComplete()
    }
  }

  updateDisplay() {
    if (!this.hasDisplayTarget) return
    const m = Math.floor(this.secondsRemaining / 60)
    const s = this.secondsRemaining % 60
    this.displayTarget.textContent = `${m}:${s.toString().padStart(2, "0")}`
  }

  updatePlayPauseButtons() {
    if (this.hasPlayBtnTarget) {
      this.playBtnTarget.style.display = this.intervalId ? "none" : ""
    }
    if (this.hasPauseBtnTarget) {
      this.pauseBtnTarget.style.display = this.intervalId ? "" : "none"
    }
  }

  onComplete() {
    this.updatePlayPauseButtons()
    // Play success sound (Web Audio API for reliability)
    this.playSuccessSound()
    // Show modal
    const modal = document.getElementById("pomodoro-done-modal")
    if (modal) modal.showModal()
  }

  /** Simple pleasant tone using Web Audio API */
  playSuccessSound() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.frequency.value = 880
      osc.type = "sine"
      gain.gain.setValueAtTime(0.15, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.4)
      osc.start(ctx.currentTime)
      osc.stop(ctx.currentTime + 0.4)
    } catch (e) {
      // Fallback: no sound if AudioContext not supported
    }
  }
}
