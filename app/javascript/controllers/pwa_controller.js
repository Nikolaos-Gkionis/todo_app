// PWA Controller for install prompts and offline functionality
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["installButton", "offlineIndicator"]

  connect() {
    // Listen for beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault()
      // Stash the event so it can be triggered later
      this.deferredPrompt = e

      // Show install button if it exists
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.style.display = 'block'
      }
    })

    // Listen for app installed event
    window.addEventListener('appinstalled', (e) => {
      console.log('PWA was installed')
      // Hide install button
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.style.display = 'none'
      }
      // Track installation
      this.trackInstall()
    })

    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      console.log('App is running in standalone mode')
    }

    // Set up offline detection
    this.setupOfflineDetection()

    // Check for updates
    this.checkForUpdates()
  }

  // Install button click handler
  async install(event) {
    event.preventDefault()

    if (!this.deferredPrompt) {
      console.log('Install prompt not available')
      return
    }

    // Show the install prompt
    this.deferredPrompt.prompt()

    // Wait for the user to respond to the prompt
    const { outcome } = await this.deferredPrompt.userChoice

    // Reset the deferred prompt
    this.deferredPrompt = null

    if (outcome === 'accepted') {
      console.log('User accepted the install prompt')
      this.trackInstall()
    } else {
      console.log('User dismissed the install prompt')
    }

    // Hide the install button
    if (this.hasInstallButtonTarget) {
      this.installButtonTarget.style.display = 'none'
    }
  }

  // Set up offline/online detection
  setupOfflineDetection() {
    const updateOnlineStatus = () => {
      const isOnline = navigator.onLine

      if (this.hasOfflineIndicatorTarget) {
        if (isOnline) {
          this.offlineIndicatorTarget.classList.add('hidden')
          this.offlineIndicatorTarget.textContent = 'Online'
        } else {
          this.offlineIndicatorTarget.classList.remove('hidden')
          this.offlineIndicatorTarget.textContent = 'Offline'
        }
      }

      // Dispatch custom event for other components
      window.dispatchEvent(new CustomEvent('connection-changed', {
        detail: { online: isOnline }
      }))
    }

    // Initial status
    updateOnlineStatus()

    // Listen for online/offline events
    window.addEventListener('online', updateOnlineStatus)
    window.addEventListener('offline', updateOnlineStatus)
  }

  // Check for service worker updates
  async checkForUpdates() {
    if ('serviceWorker' in navigator) {
      const registration = await navigator.serviceWorker.ready

      // Check for updates every 5 minutes when online
      setInterval(() => {
        if (navigator.onLine) {
          registration.update()
        }
      }, 5 * 60 * 1000)

      // Listen for update found
      registration.addEventListener('updatefound', () => {
        const newWorker = registration.installing

        newWorker.addEventListener('statechange', () => {
          if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
            this.showUpdateNotification()
          }
        })
      })
    }
  }

  // Show update notification
  showUpdateNotification() {
    // Create a simple notification banner
    const banner = document.createElement('div')
    banner.className = 'update-banner'
    banner.innerHTML = `
      <div class="update-banner__content">
        <span>A new version is available!</span>
        <button class="update-banner__button" onclick="window.location.reload()">Update Now</button>
      </div>
    `

    // Style the banner
    Object.assign(banner.style, {
      position: 'fixed',
      top: '0',
      left: '0',
      right: '0',
      background: '#4ade80',
      color: 'white',
      padding: '12px',
      textAlign: 'center',
      zIndex: '9999',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    })

    document.body.appendChild(banner)

    // Auto-hide after 10 seconds
    setTimeout(() => {
      if (banner.parentNode) {
        banner.remove()
      }
    }, 10000)
  }

  // Track installation for analytics
  trackInstall() {
    // Send analytics event
    if (typeof gtag !== 'undefined') {
      gtag('event', 'pwa_install', {
        event_category: 'engagement',
        event_label: 'pwa_install'
      })
    }

    // You could also send to your own analytics endpoint
    fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'pwa_install',
        timestamp: new Date().toISOString()
      })
    }).catch(() => {
      // Ignore errors - analytics shouldn't break the app
    })
  }

  // Register background sync for offline actions
  async registerBackgroundSync(tag) {
    if ('serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype) {
      const registration = await navigator.serviceWorker.ready
      try {
        await registration.sync.register(tag)
        console.log(`Background sync registered: ${tag}`)
      } catch (error) {
        console.log(`Background sync registration failed: ${error}`)
      }
    }
  }

  // Queue action for background sync
  queueForSync(action, data) {
    // Store in IndexedDB for background sync
    // This would be implemented based on your IndexedDB setup
    console.log(`Queueing ${action} for background sync:`, data)

    // Register appropriate background sync
    if (action === 'todo-create' || action === 'todo-update') {
      this.registerBackgroundSync('todo-sync')
    } else if (action === 'page-create' || action === 'page-update') {
      this.registerBackgroundSync('page-sync')
    }
  }
}
