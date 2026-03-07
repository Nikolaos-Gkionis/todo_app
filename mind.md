# 🧠 Project Mind: Rails PWA (BEM)

## 🎯 Hard Constraints (Token-Savers)
- **Style:** Concise, code-only unless logic is ambiguous.
- **Diffs:** Use incremental `diff` format. Never rewrite stable code.
- **Boilerplate:** Omit standard Rails imports/wrappers unless changed.

## 🏗 Tech & Architecture
- **Stack:** Rails 7+ (Hotwire/Stimulus), SQLite/Postgres.
- **Styling:** Strict **BEM**. No nesting >2 levels. 
  - `block__element--modifier`
- **PWA:** Service Worker in `app/javascript/`, manifest in `app/views/layouts/`.

## 📌 Context Snapshots
- **Active Task:** [Current focus here]
- **Architecture:** [Summary of data flow]
- **BEM Root:** `app/assets/stylesheets/components/`

## ⚡ Agent Instructions
1. Always check `.geminiignore` before scanning directories.
2. Use `find_by_name` rather than listing whole folders.
3. Reference `Gemfile` only if adding dependencies.