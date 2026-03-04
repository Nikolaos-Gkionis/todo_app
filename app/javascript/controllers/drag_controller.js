import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
    connect() {
        const isDates = this.element.dataset.dragDate !== undefined
        const isPage = this.element.dataset.dragPageId !== undefined
        const isTabs = this.element.dataset.dragTabs !== undefined

        if (isTabs) {
            // Tab reordering — horizontal drag
            this.sortable = Sortable.create(this.element, {
                animation: 150,
                handle: ".lists__tab-name",
                filter: ".lists__tab--add",
                onEnd: this.reorderPages.bind(this)
            })
            return
        }

        const isLists = this.element.dataset.dragLists !== undefined
        if (isLists) {
            // Column reordering — horizontal drag
            this.sortable = Sortable.create(this.element, {
                animation: 150,
                handle: ".lists__column-title",
                ghostClass: 'todo-item--ghost',
                forceFallback: true,   // Ensure the entire tall column dragging ghost is visually rendered
                fallbackTolerance: 3,
                onEnd: this.reorderPages.bind(this)
            })
            return
        }

        this.sortable = Sortable.create(this.element, {
            group: 'todos-shared',
            animation: 150,
            ghostClass: 'todo-item--ghost',
            chosenClass: 'todo-item--chosen',
            dragClass: 'todo-item--drag',
            onEnd: this.end.bind(this)
        })
    }

    disconnect() {
        if (this.sortable) {
            this.sortable.destroy()
        }
    }

    end(event) {
        const item = event.item
        const id = item.dataset.id
        const newContainer = event.to
        const oldContainer = event.from

        const dateStr = newContainer.dataset.dragDate
        const pageId = newContainer.dataset.dragPageId

        const csrfToken = document.querySelector('meta[name="csrf-token"]').content

        // Update location if moved to different container
        if (newContainer !== oldContainer) {
            let formData = new FormData()
            formData.append("_method", "PATCH")

            if (dateStr !== undefined) {
                formData.append("todo[due_date]", dateStr)
                formData.append("todo[page_id]", "null")
            } else if (pageId !== undefined) {
                formData.append("todo[page_id]", pageId)
                formData.append("todo[due_date]", "")
            }

            fetch(`/app/todos/${id}`, {
                method: "POST",
                headers: {
                    "X-CSRF-Token": csrfToken,
                    "Accept": "text/vnd.turbo-stream.html"
                },
                body: formData
            }).then(() => {
                this.reorderContainer(newContainer, csrfToken)
            })
        } else {
            // Same container — just reorder
            this.reorderContainer(newContainer, csrfToken)
        }
    }

    reorderContainer(container, csrfToken) {
        const ids = Array.from(container.children)
            .filter(child => child.dataset && child.dataset.id)
            .map(child => child.dataset.id)

        if (ids.length === 0) return

        let formData = new FormData()
        formData.append("_method", "PATCH")
        ids.forEach(id => formData.append("todo_ids[]", id))

        if (!csrfToken) {
            csrfToken = document.querySelector('meta[name="csrf-token"]').content
        }

        fetch("/app/todos/reorder", {
            method: "POST",
            headers: { "X-CSRF-Token": csrfToken },
            body: formData
        })
    }

    reorderPages(event) {
        const pageEls = Array.from(this.element.querySelectorAll('[data-page-id]'))
        const pageIds = pageEls.map(el => el.dataset.pageId).filter(id => id)
        if (pageIds.length === 0) return

        const csrfToken = document.querySelector('meta[name="csrf-token"]').content
        let formData = new FormData()
        formData.append("_method", "PATCH")
        pageIds.forEach(id => formData.append("page_ids[]", id))

        fetch("/app/pages/reorder", {
            method: "POST",
            headers: { "X-CSRF-Token": csrfToken },
            body: formData
        })
    }
}
