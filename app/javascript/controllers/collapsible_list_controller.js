import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["chevronBtn"]

    connect() {
        // Keep whatever the HTML already has (closed on first load, open if the user opened it)
        const dashboard = document.querySelector('.dashboard')
        this.isCollapsed = dashboard ? dashboard.classList.contains('lists-collapsed') : true
        this.applyState()
    }

    toggle() {
        this.isCollapsed = !this.isCollapsed
        this.applyState()
    }

    expand() {
        if (!this.isCollapsed) return
        this.isCollapsed = false
        this.applyState()
    }

    applyState() {
        const dashboard = document.querySelector('.dashboard')
        if (dashboard) {
            dashboard.classList.toggle('lists-collapsed', this.isCollapsed)
        }

        // Chevron points down when open, up when closed (invite to expand)
        if (this.hasChevronBtnTarget) {
            this.chevronBtnTargets.forEach(btn => {
                const svg = btn.querySelector("svg")
                if (svg) {
                    svg.style.transition = "transform 0.3s ease"
                    svg.style.transform = this.isCollapsed ? "rotate(180deg)" : "rotate(0deg)"
                }
            })
        }
    }
}
