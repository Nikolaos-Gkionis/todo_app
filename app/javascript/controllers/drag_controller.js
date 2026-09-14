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
                preventOnFilter: false,
                onEnd: this.reorderPages.bind(this)
            })
            return
        }

        const isLists = this.element.dataset.dragLists !== undefined
        if (isLists) {
            // Column reordering — horizontal drag
            // Exclude add button from reorder when on titlebar (it stays after last list)
            const isTitlebar = this.element.classList.contains('lists__titlebar-names')
            this.sortable = Sortable.create(this.element, {
                animation: 150,
                handle: ".lists__column-title",
                filter: isTitlebar ? ".lists__titlebar-add" : null,
                preventOnFilter: false,
                ghostClass: 'todo-item--ghost',
                forceFallback: true,   // Ensure the entire tall column dragging ghost is visually rendered
                fallbackTolerance: 3,
                onEnd: this.reorderPages.bind(this)
            })
            return
        }

        // Exclude add-form if it is still inside this list (week columns keep it as a sibling)
        const filter = this.element.querySelector('.not-yet-panel__add, .lists__column-add')
            ? '.not-yet-panel__add, .lists__column-add'
            : null
        const isNotYetList = this.element.closest('.not-yet-panel') != null
        this.sortable = Sortable.create(this.element, {
            group: 'todos-shared',
            animation: 150,
            ghostClass: 'todo-item--ghost',
            chosenClass: 'todo-item--chosen',
            dragClass: 'todo-item--drag',
            filter: filter,
            preventOnFilter: false,
            fallbackOnBody: true,
            swapThreshold: 0.65,
            onStart: (e) => {
                document.body.classList.add('is-dragging-todo')
                if (isNotYetList) document.body.classList.add('is-dragging-from-not-yet')
            },
            onEnd: (e) => {
                document.body.classList.remove('is-dragging-todo')
                if (isNotYetList) document.body.classList.remove('is-dragging-from-not-yet')
                this.end(e)
            }
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
        .then(res => res.ok && res.json())
        .then(data => {
            // Sync the other list region so both stay in order without manual reload
            if (data && data.success) {
                this.syncOtherListsRegion(pageIds)
            }
        })
    }

    // When lists are reordered in one region (columns or titlebar), sync the other region's DOM
    syncOtherListsRegion(pageIds) {
        const columns = document.querySelector('.lists__columns')
        const titlebar = document.getElementById('lists-titlebar-names')
        if (!columns || !titlebar) return

        const isTitlebar = this.element.id === 'lists-titlebar-names' || this.element.classList.contains('lists__titlebar-names')
        const other = isTitlebar ? columns : titlebar

        const pageChildren = Array.from(other.children).filter(el => el.dataset && el.dataset.pageId)
        const otherChildren = Array.from(other.children).filter(el => !el.dataset || !el.dataset.pageId)

        if (pageChildren.length === 0) return

        const byId = Object.fromEntries(pageChildren.map(el => [el.dataset.pageId, el]))
        pageIds.forEach(id => {
            const el = byId[id]
            if (el) other.appendChild(el)
        })
        otherChildren.forEach(el => other.appendChild(el))
    }
}
