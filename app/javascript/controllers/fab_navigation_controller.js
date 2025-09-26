import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "bottomSheet", "overlay", "closedIcon", "openIcon", "desktopNav", "themeModal"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
    // Ensure theme modal is hidden on page load
    if (this.hasThemeModalTarget) {
      this.themeModalTarget.style.display = "none"
      this.themeModalTarget.classList.add("hidden")
    }
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
    
    // Update ARIA attributes
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
    
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
    
    // Update ARIA attributes
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
    
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
    if (event.key === "Escape") {
      // Check if theme modal is open
      if (this.hasThemeModalTarget && this.themeModalTarget.style.display === "flex") {
        this.closeThemeModal()
        // Return focus to the FAB button
        if (this.hasButtonTarget) {
          this.buttonTarget.focus()
        }
      } else if (this.openValue) {
        this.close()
        // Return focus to the FAB button
        if (this.hasButtonTarget) {
          this.buttonTarget.focus()
        }
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

  // Theme modal functionality
  openThemeModal() {
    this.close() // Close the main navigation first
    this.themeModalTarget.style.display = "flex"
    this.themeModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    // Focus management
    setTimeout(() => {
      const firstFocusable = this.themeModalTarget.querySelector("button")
      if (firstFocusable) firstFocusable.focus()
    }, 100)
  }

  closeThemeModal() {
    this.themeModalTarget.style.display = "none"
    this.themeModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  closeThemeModalOnBackdrop(event) {
    if (event.target === this.themeModalTarget) {
      this.closeThemeModal()
    }
  }

  selectTheme(event) {
    const theme = event.currentTarget.dataset.theme
    
    // Remove active class from all theme options
    this.themeModalTarget.querySelectorAll('.theme-option').forEach(option => {
      option.classList.remove('active')
    })
    
    // Add active class to selected theme
    event.currentTarget.classList.add('active')
    
    // Apply the theme
    this.applyTheme(theme)
    
    // Close the modal after a short delay
    setTimeout(() => {
      this.closeThemeModal()
    }, 300)
  }

  applyTheme(theme) {
    const body = document.getElementById('app-body')
    if (!body) return
    
    // Remove all theme classes
    body.className = body.className.replace(/theme-\w+/g, '')
    
    // Add new theme class
    body.classList.add(`theme-${theme}`)
    
    // Update background class based on theme
    if (theme === 'lined') {
      body.classList.remove('notebook-background')
      body.classList.add('theme-lined')
    } else if (theme === 'graph') {
      body.classList.remove('notebook-background')
      body.classList.add('theme-graph')
    } else if (theme === 'vintage') {
      body.classList.remove('notebook-background')
      body.classList.add('theme-vintage')
    } else if (theme === 'dark') {
      body.classList.remove('notebook-background')
      body.classList.add('theme-dark')
    } else {
      // Classic theme
      body.classList.remove('theme-lined', 'theme-graph', 'theme-vintage', 'theme-dark')
      body.classList.add('notebook-background')
    }
    
    // Save theme to session
    this.saveTheme(theme)
    
    // Update FAB colors
    this.updateFabColors(theme)
  }

  saveTheme(theme) {
    // Send theme to server to save in session
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

  updateFabColors(theme) {
    const fabButton = this.buttonTarget
    if (!fabButton) return
    
    const colors = this.getThemeColors(theme)
    fabButton.style.background = colors.background
    fabButton.style.borderColor = colors.border
  }

  getThemeColors(theme) {
    switch(theme) {
      case 'classic':
        return { background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)', border: '#fef3c7' }
      case 'lined':
        return { background: 'linear-gradient(135deg, #ef4444, #dc2626)', border: '#fef3c7' }
      case 'graph':
        return { background: 'linear-gradient(135deg, #16a34a, #15803d)', border: '#fef3c7' }
      case 'vintage':
        return { background: 'linear-gradient(135deg, #b8860b, #a16207)', border: '#fef3c7' }
      case 'dark':
        return { background: 'linear-gradient(135deg, #1f2937, #111827)', border: '#374151' }
      default:
        return { background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)', border: '#fef3c7' }
    }
  }
}
