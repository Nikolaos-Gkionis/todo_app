import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "button", "viewDrawer", "viewDrawerOverlay",
    "preferencesDrawer", "preferencesOverlay",
    "prefTabBtn", "accTabBtn", "prefTabContent", "accTabContent",
    "settingsPanel", "settingsPanelOverlay"
  ]
  static values = { currentDays: { type: Number, default: 7 } }

  connect() {
    this.openValue = false
  }

  closeOnOverlay(event) {
    if (this.hasViewDrawerOverlayTarget && event.target === this.viewDrawerOverlayTarget) {
      this.closeViewDrawer()
    }
    if (this.hasPreferencesOverlayTarget && event.target === this.preferencesOverlayTarget) {
      this.closePreferences()
    }
    if (this.hasSettingsPanelOverlayTarget && event.target === this.settingsPanelOverlayTarget) {
      this.closeSettingsPanel()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      if (this.hasPreferencesDrawerTarget && this.preferencesDrawerTarget.classList.contains("side-drawer--open")) {
        this.closePreferences()
      } else if (this.hasSettingsPanelTarget && this.settingsPanelTarget.classList.contains("side-drawer--open")) {
        this.closeSettingsPanel()
      } else if (this.hasViewDrawerTarget && this.viewDrawerTarget.classList.contains("side-drawer--open")) {
        this.closeViewDrawer()
      }
    }
  }

  // ── View Drawer ──
  openViewDrawer() {
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

  // ── Preferences Drawer ──
  openPreferences() {
    if (this.hasPreferencesDrawerTarget) {
      this.preferencesDrawerTarget.classList.add("side-drawer--open")
    }
    if (this.hasPreferencesOverlayTarget) {
      // ALWAYS open strictly to the generic Settings tab defaults on boot
      this.showPreferencesTab()
    }
  }

  closePreferences() {
    if (this.hasPreferencesOverlayTarget) this.preferencesOverlayTarget.style.display = "none"
    if (this.hasPreferencesDrawerTarget) this.preferencesDrawerTarget.classList.remove("side-drawer--open")
  }

  // ── Preferences Tabs ──
  showPreferencesTab() {
    if (this.hasPrefTabContentTarget) this.prefTabContentTarget.style.display = "block"
    if (this.hasAccTabContentTarget) this.accTabContentTarget.style.display = "none"

    if (this.hasPrefTabBtnTarget) {
      this.prefTabBtnTarget.classList.add("pref-tab-btn--active")
      this.prefTabBtnTarget.style.color = ""
    }
    if (this.hasAccTabBtnTarget) {
      this.accTabBtnTarget.classList.remove("pref-tab-btn--active")
      this.accTabBtnTarget.style.color = ""
    }
  }

  showAccountTab() {
    if (this.hasPrefTabContentTarget) this.prefTabContentTarget.style.display = "none"
    if (this.hasAccTabContentTarget) this.accTabContentTarget.style.display = "block"

    if (this.hasPrefTabBtnTarget) {
      this.prefTabBtnTarget.classList.remove("pref-tab-btn--active")
      this.prefTabBtnTarget.style.color = ""
    }
    if (this.hasAccTabBtnTarget) {
      this.accTabBtnTarget.classList.add("pref-tab-btn--active")
      this.accTabBtnTarget.style.color = ""
    }
  }

  // ── Settings Panel (Legacy or secondary config) ──
  openSettingsPanel() {
    if (this.hasSettingsPanelTarget) {
      this.settingsPanelTarget.classList.add("side-drawer--open")
    }
    if (this.hasSettingsPanelOverlayTarget) {
      this.settingsPanelOverlayTarget.style.display = "block"
    }
    document.body.style.overflow = "hidden"
  }

  closeSettingsPanel() {
    if (this.hasSettingsPanelTarget) {
      this.settingsPanelTarget.classList.remove("side-drawer--open")
    }
    if (this.hasSettingsPanelOverlayTarget) {
      this.settingsPanelOverlayTarget.style.display = "none"
    }
    document.body.style.overflow = ""
  }

  // ── Theme (legacy, now also in Preferences) ──
  openThemeDrawer() {
    this.openPreferences()
  }

  closeThemeDrawer() {
    this.closePreferences()
  }

  selectTheme(event) {
    const theme = event.currentTarget.dataset.theme

    // Update active state
    document.querySelectorAll('.theme-option').forEach(option => {
      option.classList.remove('theme-option--active', 'active')
    })
    event.currentTarget.classList.add('theme-option--active')

    this.applyTheme(theme)
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
    fetch('/app/settings/theme', {
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
