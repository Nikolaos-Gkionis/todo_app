import { Controller } from "@hotwired/stimulus"

// Accordion-style FAQ with smooth height transitions.
// Uses max-height animation on transform-friendly properties
// for 60fps performance. Duration: 275ms ease-out per UX spec.
export default class extends Controller {
  static targets = ["item"]

  toggle(event) {
    const item = event.currentTarget.closest("[data-faq-target='item']")
    if (!item) return

    const answer = item.querySelector("[data-faq-answer]")
    const isOpen = item.classList.contains("is-open")

    if (this.prefersReducedMotion) {
      item.classList.toggle("is-open")
      return
    }

    if (isOpen) {
      // Collapse: set explicit height then transition to 0
      answer.style.maxHeight = answer.scrollHeight + "px"
      requestAnimationFrame(() => {
        answer.style.maxHeight = "0"
      })
      item.classList.remove("is-open")
    } else {
      // Expand: transition from 0 to scrollHeight, then remove max-height cap
      answer.style.maxHeight = answer.scrollHeight + "px"
      item.classList.add("is-open")
      answer.addEventListener("transitionend", () => {
        if (item.classList.contains("is-open")) {
          answer.style.maxHeight = "none"
        }
      }, { once: true })
    }
  }

  get prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
