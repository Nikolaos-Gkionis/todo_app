import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sortable"
export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  connect() {
    this.draggedElement = null
    this.placeholder = null
    this.setupDragAndDrop()
    this.setupContainerEvents()
  }

  setupDragAndDrop() {
    this.itemTargets.forEach((item, index) => {
      item.setAttribute('draggable', 'true')
      item.dataset.position = index + 1
      
      // Add drag event listeners
      item.addEventListener('dragstart', this.dragStart.bind(this))
      item.addEventListener('dragover', this.dragOver.bind(this))
      item.addEventListener('dragenter', this.dragEnter.bind(this))
      item.addEventListener('dragleave', this.dragLeave.bind(this))
      item.addEventListener('drop', this.drop.bind(this))
      item.addEventListener('dragend', this.dragEnd.bind(this))
    })
  }

  setupContainerEvents() {
    // Add drag events to the container itself to ensure drop works
    this.element.addEventListener('dragover', this.containerDragOver.bind(this))
    this.element.addEventListener('drop', this.containerDrop.bind(this))
  }

  containerDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  containerDrop(event) {
    event.preventDefault()
    this.drop(event)
  }

  dragStart(event) {
    this.draggedElement = event.target
    event.target.style.opacity = '0.5'
    event.target.classList.add('dragging')
    
    // Create a placeholder element
    this.placeholder = document.createElement('div')
    this.placeholder.className = 'todo-placeholder'
    this.placeholder.innerHTML = `
      <div class="border-2 border-dashed border-blue-300 bg-blue-50 rounded-lg p-4 text-center text-blue-500">
        <svg class="w-6 h-6 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"/>
        </svg>
        Drop here to reorder
      </div>
    `
    
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/html', event.target.outerHTML)
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
    
    if (event.target !== this.draggedElement && event.target.closest('[data-sortable-target="item"]')) {
      const targetItem = event.target.closest('[data-sortable-target="item"]')
      const rect = targetItem.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2
      
      if (event.clientY < midpoint) {
        targetItem.parentNode.insertBefore(this.placeholder, targetItem)
      } else {
        targetItem.parentNode.insertBefore(this.placeholder, targetItem.nextSibling)
      }
    }
  }

  dragEnter(event) {
    event.preventDefault()
    if (event.target.closest('[data-sortable-target="item"]')) {
      event.target.closest('[data-sortable-target="item"]').classList.add('drag-over')
    }
  }

  dragLeave(event) {
    if (event.target.closest('[data-sortable-target="item"]')) {
      event.target.closest('[data-sortable-target="item"]').classList.remove('drag-over')
    }
  }

  drop(event) {
    event.preventDefault()
    
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.insertBefore(this.draggedElement, this.placeholder)
      this.placeholder.remove()
    }
    
    // Remove drag-over class from all items
    this.itemTargets.forEach(item => {
      item.classList.remove('drag-over')
    })
    
    // Update positions and send to server
    this.updatePositions()
  }

  dragEnd(event) {
    event.target.style.opacity = '1'
    event.target.classList.remove('dragging')
    
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.remove()
    }
    
    // Clean up any remaining drag-over classes
    this.itemTargets.forEach(item => {
      item.classList.remove('drag-over')
    })
  }

  updatePositions() {
    const todoIds = Array.from(this.itemTargets).map(item => {
      return item.dataset.todoId
    })
    
    // Send AJAX request to update positions
    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        todo_ids: todoIds
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        // Only show error feedback, not success
        this.showFeedback(`❌ Failed to update order: ${data.error}`, 'error')
        location.reload() // Simple fallback - reload to reset order
      }
    })
    .catch(error => {
      this.showFeedback('❌ Network error', 'error')
      location.reload()
    })
  }

  showFeedback(message, type) {
    // Create a temporary feedback message
    const feedback = document.createElement('div')
    feedback.className = `fixed top-4 right-4 px-4 py-2 rounded-lg shadow-lg z-50 transition-all duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
    }`
    feedback.textContent = message
    
    document.body.appendChild(feedback)
    
    // Animate in
    setTimeout(() => feedback.classList.add('opacity-100'), 10)
    
    // Remove after 3 seconds
    setTimeout(() => {
      feedback.classList.add('opacity-0')
      setTimeout(() => feedback.remove(), 300)
    }, 3000)
  }
}
