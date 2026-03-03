import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "button", "bottomSheet", "overlay", "closedIcon", "openIcon",
    "desktopNav",
    "themeDrawer", "themeDrawerOverlay",
    "viewDrawer", "viewDrawerOverlay"
  ]
  static values = { open: Boolean, currentDays: { type: Number, default: 7 } }

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

  isDesktop() {
    return window.innerWidth > 768
  }

  open() {
    this.openValue = true

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
    if (this.hasClosedIconTarget) this.closedIconTarget.classList.add("hidden")
    if (this.hasOpenIconTarget) {
      this.openIconTarget.classList.remove("hidden")
      this.openIconTarget.classList.remove("fab__icon--hidden")
    }

    if (this.isDesktop()) {
      this.desktopNavTarget.classList.remove("hidden")
    } else {
      this.bottomSheetTarget.classList.remove("hidden")
      this.overlayTarget.classList.remove("hidden")
      this.bottomSheetTarget.style.transform = "translateY(0)"
      document.body.style.overflow = "hidden"

      setTimeout(() => {
        const firstFocusable = this.bottomSheetTarget.querySelector("a, button")
        if (firstFocusable) firstFocusable.focus()
      }, 100)
    }
  }

  close() {
    this.openValue = false

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
    if (this.hasClosedIconTarget) this.closedIconTarget.classList.remove("hidden")
    if (this.hasOpenIconTarget) {
      this.openIconTarget.classList.add("hidden")
      this.openIconTarget.classList.add("fab__icon--hidden")
    }

    if (this.isDesktop()) {
      this.desktopNavTarget.classList.add("hidden")
    } else {
      this.bottomSheetTarget.classList.add("hidden")
      this.overlayTarget.classList.add("hidden")
      this.bottomSheetTarget.style.transform = "translateY(100%)"
    }
    document.body.style.overflow = ""
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
    // Also close drawers if their overlay is clicked
    if (this.hasThemeDrawerOverlayTarget && event.target === this.themeDrawerOverlayTarget) {
      this.closeThemeDrawer()
    }
    if (this.hasViewDrawerOverlayTarget && event.target === this.viewDrawerOverlayTarget) {
      this.closeViewDrawer()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      if (this.hasThemeDrawerTarget && this.themeDrawerTarget.classList.contains("side-drawer--open")) {
        this.closeThemeDrawer()
      } else if (this.hasViewDrawerTarget && this.viewDrawerTarget.classList.contains("side-drawer--open")) {
        this.closeViewDrawer()
      } else if (this.openValue) {
        this.close()
        if (this.hasButtonTarget) this.buttonTarget.focus()
      }
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

  // ── View Drawer ──
  openViewDrawer() {
    this.close()
    if (this.hasViewDrawerTarget) {
      this.viewDrawerTarget.classList.add("side-drawer--open")
    }
    if (this.hasViewDrawerOverlayTarget) {
      this.viewDrawerOverlayTarget.style.display = "block"
    }
    document.body.style.overflow = "hidden"
  }

  closeViewDrawer() {
    if (this.hasViewDrawerTarget) {
      this.viewDrawerTarget.classList.remove("side-drawer--open")
    }
    if (this.hasViewDrawerOverlayTarget) {
      this.viewDrawerOverlayTarget.style.display = "none"
    }
    document.body.style.overflow = ""
  }

  // ── Theme Drawer ──
  openThemeDrawer() {
    this.close()
    if (this.hasThemeDrawerTarget) {
      this.themeDrawerTarget.classList.add("side-drawer--open")
    }
    if (this.hasThemeDrawerOverlayTarget) {
      this.themeDrawerOverlayTarget.style.display = "block"
    }
    document.body.style.overflow = "hidden"
  }

  closeThemeDrawer() {
    if (this.hasThemeDrawerTarget) {
      this.themeDrawerTarget.classList.remove("side-drawer--open")
    }
    if (this.hasThemeDrawerOverlayTarget) {
      this.themeDrawerOverlayTarget.style.display = "none"
    }
    document.body.style.overflow = ""
  }

  selectTheme(event) {
    const theme = event.currentTarget.dataset.theme

    const container = this.hasThemeDrawerTarget ? this.themeDrawerTarget : this.element
    container.querySelectorAll('.theme-option').forEach(option => {
      option.classList.remove('theme-option--active', 'active')
    })
    event.currentTarget.classList.add('theme-option--active')

    this.applyTheme(theme)

    setTimeout(() => {
      this.closeThemeDrawer()
    }, 300)
  }

  applyTheme(theme) {
    const body = document.getElementById('app-body')
    if (!body) return

    body.className = body.className.replace(/theme-\w+/g, '')
    body.classList.add(`theme-${theme}`)

    if (theme === 'classic') {
      body.classList.remove('theme-lined', 'theme-graph', 'theme-vintage', 'theme-dark')
    }

    localStorage.setItem('notebook-theme', theme)
    this.saveTheme(theme)
  }

  saveTheme(theme) {
    fetch('/settings/theme', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ theme: theme })
    }).catch(error => {
      console.error('Error saving theme:', error)
    })
  }
}
