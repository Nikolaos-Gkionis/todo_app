import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
    connect() {
        this.sortable = Sortable.create(this.element, {
            group: 'shared', // set lists to same group
            animation: 150,
            onEnd: this.end.bind(this)
        })
    }

    disconnect() {
        if (this.sortable) {
            this.sortable.destroy()
        }
    }

    end(event) {
        const item = event.item;
        const id = item.dataset.id;
        const newContainer = event.to;

        // Extract contextual data from the new container
        const dateStr = newContainer.dataset.dragDate;
        const pageId = newContainer.dataset.dragPageId;

        let formData = new FormData();
        formData.append("_method", "PATCH");

        if (dateStr !== undefined) {
            formData.append("todo[due_date]", dateStr);
            formData.append("todo[page_id]", "null");
        } else if (pageId !== undefined) {
            formData.append("todo[page_id]", pageId);
            formData.append("todo[due_date]", "");
        }

        const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

        // First update the item's date/page
        fetch(`/app/todos/${id}`, {
            method: "POST",
            headers: {
                "X-CSRF-Token": csrfToken,
                "Accept": "text/vnd.turbo-stream.html"
            },
            body: formData
        }).then(() => {
            // After updating the item's location, trigger reorder on the destination container
            this.reorderContainer(newContainer);
            // We should probably also reorder the source container if it changed, but usually the position 
            // of remaining items will just implicitly shift up which is fine.
        });
    }

    reorderContainer(container) {
        const ids = Array.from(container.children)
            .filter(child => child.dataset && child.dataset.id)
            .map(child => child.dataset.id);

        if (ids.length === 0) return;

        let formData = new FormData();
        formData.append("_method", "PATCH");
        ids.forEach(id => formData.append("todo_ids[]", id));

        const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
        fetch("/app/todos/reorder", {
            method: "POST",
            headers: { "X-CSRF-Token": csrfToken },
            body: formData
        });
    }
}
