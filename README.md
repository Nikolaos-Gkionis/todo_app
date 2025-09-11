# Todo App - Rails Learning Project

A fully functional todo application built with Rails 8.2 and Tailwind CSS.

## Current Features ✅

- **Project Management**: Create and view projects with names and descriptions
- **Todo Management**: Add todos to projects with titles and optional notes
- **Interactive Completion**: Click checkboxes to mark todos as complete/incomplete
- **Clean UI**: Responsive design with Tailwind CSS
- **Flash Messages**: User feedback for successful actions
- **Data Validation**: Proper validation on all models

## Tech Stack

- **Rails**: 8.2.1
- **Ruby**: 3.4.5
- **Database**: SQLite3
- **CSS Framework**: Tailwind CSS
- **JavaScript**: Rails default (Turbo + Stimulus)

## Models & Relationships

- `User` has many `Projects`
- `Project` belongs to `User`, has many `Todos`
- `Todo` belongs to `Project`

## Current Status

Basic todo functionality is complete! You can:

1. Create projects
2. Add todos to projects
3. Mark todos as complete
4. Navigate between project list and project details

## Next Steps

- [ ] User authentication system
- [ ] Edit/delete projects and todos
- [ ] Todo positioning/ordering
- [ ] Project colors and themes
- [ ] Due dates for todos
- [ ] Search and filtering

## Getting Started

```bash
# Start the Rails server
rails server

# In another terminal, start Tailwind CSS compilation
rails tailwindcss:watch
```

Visit http://localhost:3000 to use the app!
