# Todo-it.app UI Style and Functionality Documentation

## Overview
Todo-it.app is designed as a highly minimalist to-do list application for users who want a simple, uncluttered system without complex project folders, tags, or contexts. The application focuses on a time-based visual structure, split between daily calendar tasks and flexible "Someday" lists.

---

## UI Style & Layout Data Table

| UI Category | Feature | Description | 
| :--- | :--- | :--- | 
| **General Aesthetic** | Minimalist Design | A clean, stripped-down interface designed to minimize distractions and clutter. |
| **Web Layout** | Split-Section View | The interface features two main sections: a top section displaying a horizontal timeline of days (week-at-a-glance), and a bottom section for custom, non-time-bound "Someday" lists. |
| **Customization** | Visual Preferences | Users can adjust theme colors, text sizes, line spacing, and the number of columns displayed in the web view. |
| **Visual Feedback** | Task Completion | Completed tasks visually "grey out" to indicate they are finished. Users can also toggle "Celebrations" on for a visual boost when checking off a task. |
| **Visibility** | Completed Tasks | Users can choose to show or hide completed to-dos via the Preferences menu. |

---

## Core Functionality Data Table

| Category | Feature | Description & Interactions |
| :--- | :--- | :--- |
| **Task Management** | Add & Complete | Type to add tasks; tap/click to edit; check off to mark complete; delete to remove. |
| **Task Movement** | Drag-and-Drop | Users can drag and drop tasks to rearrange their order, move them to different dates, or drop them into Someday lists. |
| **Automation** | Automatic Rollover | Any unfinished tasks at the end of the day automatically roll over to the next day. |
| **Recurring Tasks** | Natural Language | Create repeating tasks by typing "every" followed by the frequency (e.g., "every day", "every weekday", "every month"). Managed via a Recurring icon. |
| **Formatting** | Markdown & Toolbars | Style text using Markdown (e.g., `**bold**`, `*italic*`), a hover formatting toolbar, or keyboard shortcuts (`Ctrl/Cmd+B`, `Ctrl/Cmd+I`, `Ctrl/Cmd+K`). |
| **Task Notes** | Extra Context | Attach ideas, links, subtasks (`[]`), bulleted lists (`-`), or images to specific tasks. Notes are fully editable on web but read-only on mobile. |
| **Organization** | Someday Lists & Tabs | Create custom lists for flexible planning (e.g., "this month", "shopping"). Group these lists into customizable "Tabs" to prioritize or hide contexts. |
| **External Input** | Email to Task | Users can email tasks directly to their Todo-it.app "today" list using a unique email address. |
| **Notifications** | Daily Digest | Users can schedule a daily email summarizing their to-dos, and reply directly to the email to add new tasks. |
| **Calendar** | Custom Holidays | Add yearly occasions (birthdays, anniversaries) to the top of a day's timeline without them rolling over like standard tasks. |

---

## Platform-Specific Navigation & Functionality

### Web Browser Interaction
*   **Navigation:** Use the top arrows to navigate the timeline, click the **calendar icon** to jump to future dates, or click **"Today"** to instantly return to the current day.
*   **Search:** A search function is located in the top left corner to find lost tasks.
*   **List Management:** Manage Someday lists by clicking the vertical ellipsis (`⋮`) to rename, move between Tabs, or add lists to either side.
*   **Keyboard Shortcuts:**
    *   `Ctrl + Shift + Z`: Undo a deleted task.
    *   `Ctrl + [` or `Ctrl + ]`: Navigate to the previous or next week.
    *   `Ctrl + Shift + H`: Jump back to "Today".

### PWA Mobile App Gestures 
*   **Adding Tasks:** Pull down on the screen to add items to the top of the list, or tap the plus sign/empty space below to add to the bottom.
*   **Task Actions:** Swipe right on a task to push it to tomorrow, or swipe left to delete it entirely.
*   **Date Navigation:** Drag along the bottom ticker to move dates, or swipe up from the bottom to open a full calendar view.
*   **Someday Menu:** Tap "Someday" on the bottom bar to open non-time-bound lists.
*   **Widget:** An iOS widget is available for easy home screen access.
```