# Fixes and Refinements

1. **Remove `pages/` Path:** Ensure the application does not navigate away to separate `pages/` URLs. Interaction with lists should remain on the dashboard or be removed if unnecessary.
2. **Tabs Functionality:** The custom list tabs need to function correctly, similar to the calendar navigation.
3. **Calendar Icon:** Fix the calendar icon so that it is functional, rather than a static button.
4. **Remove Half Moon / Re-instate FAB:** Remove the half-moon theme toggle from the top header and restore the Floating Action Button (FAB) by removing the overriding CSS. 
5. **Reload on Task Add:** When a new task is added, perform a page reload to ensure it is placed correctly in order.
6. **Drag and Drop:** Fix the drag-and-drop functionality in the daily calendar view. Currently, the entire block of todos is picked up instead of individual items.
