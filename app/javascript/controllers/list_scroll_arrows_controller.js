import { Controller } from "@hotwired/stimulus"

// Shows/hides the ‹ › scroll arrows based on whether list headers overflow the view.
export default class extends Controller {
  static targets = ["scrollContainer", "arrows"]

  connect() {
    this.updateVisibility()
    this.observeResize()
    this.observeMutations()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.mutationObserver?.disconnect()
  }

  // Re-check overflow when the scroll container or viewport changes size
  observeResize() {
    if (!this.hasScrollContainerTarget) return

    this.resizeObserver = new ResizeObserver(() => this.updateVisibility())
    this.resizeObserver.observe(this.scrollContainerTarget)
  }

  // Re-check when lists are added/removed (e.g. new list created)
  observeMutations() {
    if (!this.hasScrollContainerTarget) return

    this.mutationObserver = new MutationObserver(() => this.updateVisibility())
    this.mutationObserver.observe(this.scrollContainerTarget, {
      childList: true,
      subtree: true
    })
  }

  updateVisibility() {
    if (!this.hasScrollContainerTarget || !this.hasArrowsTarget) return

    const el = this.scrollContainerTarget
    const hasOverflow = el.scrollWidth > el.clientWidth

    this.arrowsTarget.classList.toggle("lists__titlebar-scroll-arrows--visible", hasOverflow)
  }
}
