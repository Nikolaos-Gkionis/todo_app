import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="typewriter"
export default class extends Controller {
  static values = { 
    text: String,
    speed: { type: Number, default: 50 }, // milliseconds per character
    delay: { type: Number, default: 0 }   // delay before starting
  }

  connect() {
    console.log('Typewriter connected:', this.textValue)
    this.originalText = this.textValue || this.element.textContent.trim()
    this.element.textContent = '' // Clear the element
    this.element.style.position = 'relative'
    
    // Add a blinking cursor
    this.cursor = document.createElement('span')
    this.cursor.textContent = '|'
    this.cursor.className = 'typewriter-cursor'
    this.cursor.style.cssText = `
      animation: blink 1s infinite;
      color: currentColor;
      font-weight: normal;
    `
    this.element.appendChild(this.cursor)
    
    // Add cursor animation CSS if not already present
    this.addCursorAnimation()
    
    // Start typing after delay
    setTimeout(() => {
      this.startTyping()
    }, this.delayValue)
  }

  addCursorAnimation() {
    if (!document.getElementById('typewriter-styles')) {
      const style = document.createElement('style')
      style.id = 'typewriter-styles'
      style.textContent = `
        @keyframes blink {
          0%, 50% { opacity: 1; }
          51%, 100% { opacity: 0; }
        }
        .typewriter-cursor {
          display: inline-block;
          margin-left: 2px;
        }
      `
      document.head.appendChild(style)
    }
  }

  startTyping() {
    let currentIndex = 0
    const text = this.originalText
    
    const typeInterval = setInterval(() => {
      if (currentIndex < text.length) {
        // Insert character before cursor
        this.element.insertBefore(
          document.createTextNode(text[currentIndex]),
          this.cursor
        )
        currentIndex++
      } else {
        // Typing complete - remove cursor after a moment
        clearInterval(typeInterval)
        setTimeout(() => {
          if (this.cursor && this.cursor.parentNode) {
            this.cursor.remove()
          }
        }, 1000)
      }
    }, this.speedValue)
  }

  disconnect() {
    // Clean up if controller is removed
    if (this.cursor && this.cursor.parentNode) {
      this.cursor.remove()
    }
  }
}
