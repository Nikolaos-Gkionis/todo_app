import { Controller } from "@hotwired/stimulus"

// Used only on todos inserted via Turbo Stream after create.
// Opens the bottom drawer if it is closed, then scrolls the new row into view.
export default class extends Controller {
  connect() {
    window.dispatchEvent(new CustomEvent("lists-drawer-expand"))
    requestAnimationFrame(() => {
      this.element.scrollIntoView({ block: "nearest", behavior: "smooth" })
    })
  }
}
