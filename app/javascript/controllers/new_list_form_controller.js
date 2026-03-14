import { Controller } from "@hotwired/stimulus"

// Handles "Create New List" form via fetch — avoids redirect/cache issues from full form submit
export default class extends Controller {
  static values = { redirectUrl: { type: String, default: "/app" } }

  submit(e) {
    e.preventDefault()
    const form = this.element
    const submitBtn = form.querySelector('input[type="submit"], button[type="submit"]')
    const originalLabel = submitBtn ? (submitBtn.value || submitBtn.textContent) : ""
    if (submitBtn) {
      submitBtn.disabled = true
      if (submitBtn.tagName === "INPUT") submitBtn.value = "Creating…"
      else submitBtn.textContent = "Creating…"
    }

    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    const authToken = form.querySelector('input[name="authenticity_token"]')?.value || csrf

    // Build params like a normal form: application/x-www-form-urlencoded (Rails default)
    const params = new URLSearchParams()
    if (authToken) params.set("authenticity_token", authToken)
    const nameInput = form.querySelector('input[name="page[name]"]')
    if (nameInput?.value) params.set("page[name]", nameInput.value.trim())
    params.set("commit", "Create")

    // Use .json so Rails reliably returns JSON (and we get clear success/redirect handling)
    const actionUrl = form.action.replace(/\?.*$/, "").endsWith(".json") ? form.action : form.action + (form.action.includes("?") ? "&" : "?") + "format=json"
    fetch(actionUrl, {
      method: "POST",
      body: params.toString(),
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrf || form.querySelector('input[name="authenticity_token"]')?.value || "",
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      },
      redirect: "manual" // Handle redirect ourselves to ensure fresh load
    })
      .then(res => {
        // With redirect:"manual", res.url stays as request URL; use Location for redirects
        const loc = res.headers.get("Location")
        if (res.status === 302 || res.status === 303) {
          const dest = (loc || this.redirectUrlValue)
          const withPanel = dest.includes("panel=") ? dest : dest + (dest.includes("?") ? "&" : "?") + "panel=open"
          const fresh = withPanel + (withPanel.includes("?") ? "&" : "?") + "_=" + Date.now()
          window.location.href = fresh
          return
        }
        if (res.redirected || res.type === "opaqueredirect" || (res.status >= 300 && res.status < 400)) {
          const url = loc || res.url || this.redirectUrlValue
          const dest = (url.includes("?") ? url : url + "?panel=open").replace(/([?&])panel=[^&]*(&|$)/, "$1panel=open$2")
          const fresh = dest + (dest.includes("?") ? "&" : "?") + "_=" + Date.now()
          window.location.href = fresh
          return
        }
        if (res.ok) {
          return res.json().then(data => {
            const baseUrl = data.redirect || this.redirectUrlValue
            const url = baseUrl + (baseUrl.includes("?") ? "&" : "?") + "_=" + Date.now()
            // Bypass Turbo so we get a fresh server render (new tab appears)
            const a = document.createElement("a")
            a.href = url
            a.setAttribute("data-turbo", "false")
            document.body.appendChild(a)
            a.click()
            a.remove()
          }).catch(() => {
            // Fallback if response isn't JSON (e.g. old server)
            window.location.href = this.redirectUrlValue + (this.redirectUrlValue.includes("?") ? "&" : "?") + "panel=open&_=" + Date.now()
          })
        }
        if (res.status === 403 || res.status === 422) {
          return res.json().then(data => {
            alert(data.message || ("Could not create list: " + (data.errors || [ "Please check your input" ]).join(", ")))
          })
        }
        throw new Error("Request failed")
      })
      .catch(() => {
        alert("Something went wrong. Please try again.")
      })
      .finally(() => {
        if (submitBtn) {
          submitBtn.disabled = false
          if (submitBtn.tagName === "INPUT") submitBtn.value = originalLabel
          else submitBtn.textContent = originalLabel
        }
      })
  }
}
