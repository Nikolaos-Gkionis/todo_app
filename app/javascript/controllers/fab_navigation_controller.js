import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "bottomSheet", "overlay", "closedIcon", "openIcon", "desktopNav"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
  }

  toggle() {
    if (this.openValue) {
      this.close()
    } else {
      this.open()
    }
  }

  // Check if we're on desktop (screen width > 768px)
  isDesktop() {
    return window.innerWidth > 768
  }

  open() {
    this.openValue = true
    
    if (this.isDesktop()) {
      // Desktop: Show navigation bar
      this.desktopNavTarget.classList.remove("hidden")
    } else {
      // Mobile/Tablet: Show bottom sheet
      this.bottomSheetTarget.classList.remove("hidden")
      this.overlayTarget.classList.remove("hidden")
      
      // Reset transform to show the bottom sheet
      this.bottomSheetTarget.style.transform = "translateY(0)"
      
      // Prevent body scroll on mobile
      document.body.style.overflow = "hidden"
      
      // Focus management
      setTimeout(() => {
        const firstFocusable = this.bottomSheetTarget.querySelector("a, button")
        if (firstFocusable) firstFocusable.focus()
      }, 100)
    }
    
    if (this.hasClosedIconTarget) this.closedIconTarget.classList.add("hidden")
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove("hidden")
  }

  close() {
    this.openValue = false
    
    if (this.isDesktop()) {
      // Desktop: Hide navigation bar
      this.desktopNavTarget.classList.add("hidden")
    } else {
      // Mobile/Tablet: Hide bottom sheet
      this.bottomSheetTarget.classList.add("hidden")
      this.overlayTarget.classList.add("hidden")
      
      // Reset transform
      this.bottomSheetTarget.style.transform = "translateY(100%)"
    }
    
    if (this.hasClosedIconTarget) this.closedIconTarget.classList.remove("hidden")
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add("hidden")
    
    // Restore body scroll
    document.body.style.overflow = ""
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.openValue) {
      this.close()
    }
  }

  // Touch gesture handling
  touchStart(event) {
    this.startY = event.touches[0].clientY
    this.isDragging = true
  }

  touchMove(event) {
    if (!this.isDragging) return
    this.currentY = event.touches[0].clientY
    const deltaY = this.currentY - this.startY
    
    if (deltaY > 0) {
      this.bottomSheetTarget.style.transform = `translateY(${Math.min(deltaY, 100)}px)`
    }
  }

  touchEnd(event) {
    if (!this.isDragging) return
    this.isDragging = false
    
    const deltaY = this.currentY - this.startY
    if (deltaY > 50) {
      this.close()
    } else {
      this.bottomSheetTarget.style.transform = "translateY(0)"
    }
  }
}
