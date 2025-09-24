import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "confirmButton", "cancelButton"]

  connect() {
    console.log("Logout controller connected!")
    
    // Close modal when clicking outside
    this.modalTarget.addEventListener("click", (e) => {
      if (e.target === this.modalTarget) {
        this.hideModal()
      }
    })

    // Close modal with Escape key
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && this.modalTarget.classList.contains("show")) {
        this.hideModal()
      }
    })
  }

  showModal() {
    console.log("Show modal called!")
    console.log("Modal target:", this.modalTarget)
    
    if (this.modalTarget) {
      this.modalTarget.classList.add("show")
      document.body.style.overflow = "hidden" // Prevent background scrolling
      this.modalTarget.focus()
    } else {
      console.error("Modal target not found!")
    }
  }

  hideModal() {
    this.modalTarget.classList.remove("show")
    document.body.style.overflow = "" // Restore scrolling
  }

  confirmLogout() {
    // Create a form and submit it to logout
    const form = document.createElement("form")
    form.method = "POST"
    form.action = "/logout"
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
    const tokenInput = document.createElement("input")
    tokenInput.type = "hidden"
    tokenInput.name = "authenticity_token"
    tokenInput.value = csrfToken
    
    // Add method override for DELETE
    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "delete"
    
    form.appendChild(tokenInput)
    form.appendChild(methodInput)
    document.body.appendChild(form)
    form.submit()
  }
}
