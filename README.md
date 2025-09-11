# Todo App - Rails Learning Project

A fully functional todo application built with Rails 8.0 and Tailwind CSS, featuring complete user authentication and secure data isolation.

## Current Features ✅

- **🔐 User Authentication**: Complete signup/login system with bcrypt password security
- **👤 User Isolation**: Each user sees only their own projects and todos
- **📋 Project Management**: Create and view projects with names and descriptions
- **✅ Todo Management**: Add todos to projects with titles and optional notes
- **🎯 Interactive Completion**: Click checkboxes to mark todos as complete/incomplete
- **🎨 Clean UI**: Responsive design with Tailwind CSS
- **💬 Flash Messages**: User feedback for successful actions
- **🔒 Security**: CSRF protection, strong parameters, and authentication filters
- **📱 Modern Rails**: Uses Turbo for seamless JavaScript interactions

## Tech Stack

- **Rails**: 8.0.2
- **Ruby**: 3.4.5
- **Database**: SQLite3
- **Authentication**: bcrypt with has_secure_password
- **CSS Framework**: Tailwind CSS
- **JavaScript**: Rails default (Turbo + Stimulus)

## Models & Relationships

- `User` has many `Projects`
- `Project` belongs to `User`, has many `Todos`
- `Todo` belongs to `Project`

## Current Status

**Authentication & Core Features Complete!** 🎉

You can now:

1. **Sign up** for a new account with email and password
2. **Login/Logout** securely with session management
3. **Create projects** tied to your user account
4. **Add todos** to your projects with titles and notes
5. **Mark todos complete** with interactive checkboxes
6. **Navigate** between project list and project details
7. **Security** - only see your own data, protected from unauthorized access

## Next Steps

- [x] ~~User authentication system~~ ✅ **COMPLETED**
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

**First time setup:**

1. Click "Sign Up" to create your account
2. Start creating projects and todos!
3. Each user has their own private workspace

## Key Learning Achievements 🎓

Through building this app, you've learned:

- **Rails MVC Architecture** - Models, Views, Controllers working together
- **Database Relationships** - has_many, belongs_to associations
- **Authentication Security** - Password hashing, sessions, CSRF protection
- **Authorization Patterns** - before_action filters, user data isolation
- **Modern Rails** - Turbo for JavaScript, form helpers, flash messages
- **RESTful Routes** - Proper HTTP methods for different actions
- **UI/UX Design** - Responsive layouts with Tailwind CSS
