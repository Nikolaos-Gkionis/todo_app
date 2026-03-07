import { Controller } from "@hotwired/stimulus"

// Scroll-triggered reveal animations using IntersectionObserver.
// Adds .is-visible to .mkt-reveal elements when they enter the viewport.
// Also manages sticky navbar scroll state for marketing pages.
// Fully respects prefers-reduced-motion per WCAG 2.3.3.
export default class extends Controller {
  connect() {
    this.prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.setupRevealObserver()
    this.setupNavbarScroll()
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
    if (this.scrollCleanup) this.scrollCleanup()
  }

  setupRevealObserver() {
    const items = this.element.querySelectorAll(".mkt-reveal")

    if (this.prefersReducedMotion) {
      items.forEach(el => el.classList.add("is-visible"))
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible")
          this.observer.unobserve(entry.target)
        }
      })
    }, {
      threshold: 0.12,
      rootMargin: "0px 0px -48px 0px"
    })

    items.forEach(el => this.observer.observe(el))
  }

  setupNavbarScroll() {
    const navbar = document.querySelector(".navbar")
    if (!navbar) return

    const handler = () => {
      navbar.classList.toggle("navbar--scrolled", window.scrollY > 48)
    }

    window.addEventListener("scroll", handler, { passive: true })
    handler()
    this.scrollCleanup = () => window.removeEventListener("scroll", handler)
  }
}
