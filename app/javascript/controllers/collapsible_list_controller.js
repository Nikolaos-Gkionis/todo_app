import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["chevronBtn"]

    connect() {
        this.isCollapsed = false
    }

    toggle() {
        this.isCollapsed = !this.isCollapsed

        const dashboard = document.querySelector('.dashboard')
        if (dashboard) {
            dashboard.classList.toggle('lists-collapsed', this.isCollapsed)
        }

        // Rotate chevron: down (0°) = open, up (180°) = collapsed
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
