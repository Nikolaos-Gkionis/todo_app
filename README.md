# Todo-it - Beautiful Notebook-Style Todo App

A stunning, professional notebook-style todo application built with Rails 8.0, featuring authentic hand-drawn aesthetics, complete user authentication, and a delightful productivity experience that feels like writing in a real moleskin notebook.

## ✨ Complete Feature Set

### 🔐 **Secure Authentication System**

- **Complete signup/login** with bcrypt password hashing
- **Session management** with secure logout
- **User data isolation** - each user sees only their own content
- **CSRF protection** and strong parameter validation
- **Password confirmation** and email validation

### 📝 **Full Project & Todo Management**

- **Complete CRUD operations** for projects and todos
- **Rich project details** with names, descriptions, and creation dates
- **Advanced todo management** with titles, notes, completion status, and due dates
- **Smart due date system** with visual priority indicators (overdue, due today, due soon)
- **Intelligent auto-sorting** - due dates prioritized automatically
- **Smart progress tracking** with completion counters (e.g., "3/7 completed")
- **Visual progress bars** showing completion percentage
- **Collapsible forms** for seamless todo creation

### 🎨 **5 Stunning Notebook Themes**

1. **Classic Dotted** - Original moleskin notebook with dotted background
2. **Lined Paper** - Traditional notebook with horizontal lines
3. **Graph Paper** - Perfect grid pattern for organized minds
4. **Vintage Paper** - Warm, aged paper feel with sepia tones
5. **Dark Mode** - Easy on the eyes with off-white text and light blue accents

### 🖊️ **Authentic Hand-Drawn Aesthetics**

- **Hand-drawn checkboxes** (24x24px) with organic, wobbly lines
- **Custom SVG underlines** - no straight lines anywhere in the interface
- **Wavy red margin lines** that look genuinely hand-sketched
- **Transparent forms** with hand-drawn underlines for authentic feel
- **Gloria Hallelujah font** from Google Fonts with smart fallbacks
- **"Todo-it" branding** with custom checked checkbox logo

### ⚡ **Advanced User Experience**

- **Magical typewriter animations** - New todos appear as if written with a pen in real-time
- **Smooth checkbox animations** - Delightful hover and completion effects
- **Drag-and-drop todo reordering** - Effortlessly reorganize todos with smooth visual feedback
- **Smart due date management** - Color-coded priority badges (red=overdue, orange=today, green=soon)
- **Intelligent auto-prioritization** - Due todos automatically sort to the top
- **Theme persistence** across all pages with instant switching via theme selector
- **Auto-dismissing flash messages** (3-second timeout with smooth fade)
- **Turbo-powered navigation** for SPA-like speed
- **Mobile-first responsive design** optimized for touch devices and desktop

### 🎯 **Smart UI/UX Design**

- **Contextual theme selector** - only visible on main projects page
- **Clean individual project pages** - distraction-free when working on todos
- **Instant theme switching** - no page refreshes required
- **Professional flash messaging** with dark mode support
- **Collapsible todo forms** with focus management
- **Progress visualization** with animated progress bars

## Tech Stack

- **Backend**: Rails 8.0.2 with Ruby 3.4.5
- **Database**: SQLite3 for development
- **Authentication**: bcrypt with Rails `has_secure_password`
- **Styling**: Custom CSS with hand-drawn SVG elements + Tailwind utilities
- **Typography**: Google Fonts (Gloria Hallelujah) with comprehensive fallbacks
- **Graphics**: Custom hand-drawn SVG elements throughout
- **JavaScript**: Rails Turbo + vanilla JS for smooth interactions
- **Asset Pipeline**: Rails 8 asset pipeline with CSS bundling
- **Theme System**: localStorage persistence with instant switching

## Models & Relationships

```ruby
User
├── has_many :projects (dependent: :destroy)
├── has_secure_password
└── validates email uniqueness & format

Project
├── belongs_to :user
├── has_many :todos (dependent: :destroy)
├── progress tracking methods (total_todos_count, completed_todos_count, etc.)
└── validates name presence & length

Todo
├── belongs_to :project
├── boolean :completed
└── text fields: title, notes
```

## Current Status

**🎉 Production-Ready Notebook App - Complete!**

### ✅ **Completed Features**

- **Full authentication system** with secure user isolation
- **Complete CRUD operations** for projects and todos with edit/delete
- **5 beautiful themes** with instant switching and persistence
- **Smart progress tracking** with counters and visual progress bars
- **Intuitive drag-and-drop reordering** for todos
- **Auto-dismissing notifications** with smooth animations
- **Hand-drawn aesthetics** throughout - checkboxes, underlines, margins
- **Professional UX** with contextual UI elements
- **Turbo-compatible JavaScript** with error-free navigation
- **Dark mode support** with perfect contrast and readability
- **Theme persistence** across all pages and browser sessions

### 🚀 **Advanced Features Implemented**

- **Todo completion counters** per project ("3/7 completed")
- **Progress visualization** with animated bars
- **Keyboard shortcuts** for rapid productivity
- **5-theme system** with instant switching
- **Dark mode** with authentic notebook feel
- **Theme persistence** across sessions
- **Auto-dismissing flash messages**
- **Contextual UI** (theme selector only where needed)

## Getting Started

```bash
# Clone and setup
git clone [repository-url]
cd todo_app

# Install dependencies
bundle install

# Setup database
rails db:migrate
rails db:seed

# Start the application
rails server

# In another terminal (optional - for CSS changes)
rails tailwindcss:watch
```

Visit http://localhost:3000 to experience the app!

### **First Time Setup:**

1. Click "Sign Up" to create your account
2. Start creating projects and todos
3. Try different themes using the theme selector
4. Drag and drop todos to reorder them within projects
5. Each user has their own private workspace

## Interactive Features

- **Click theme selector** - Switch between 5 beautiful notebook themes
- **Drag and drop** - Reorder todos within any project
- **Click checkboxes** - Mark todos as complete/incomplete
- **Collapsible forms** - Clean interface with expandable todo creation

## Key Learning Achievements 🎓

Through building this app, you've mastered:

### **Rails Fundamentals**

- **MVC Architecture** - Clean separation of concerns
- **Database Relationships** - has_many, belongs_to associations
- **Authentication & Authorization** - Secure user systems
- **RESTful Routes** - Proper HTTP methods and conventions
- **Modern Rails 8** - Latest patterns and best practices

### **Frontend Excellence**

- **Custom CSS Design** - Hand-crafted aesthetic without frameworks
- **SVG Graphics** - Custom hand-drawn elements
- **JavaScript Integration** - Turbo-compatible interactions
- **Theme Systems** - Advanced CSS architecture
- **Responsive Design** - Works on all devices

### **Advanced Features**

- **Progress Tracking** - Database calculations and UI visualization
- **Keyboard Shortcuts** - Advanced user interactions
- **Theme Persistence** - localStorage and instant switching
- **Auto-dismissing UI** - Professional notification systems
- **Error-free JavaScript** - Turbo-compatible code

### **Professional Development**

- **User Experience Design** - Thoughtful, contextual interfaces
- **Performance Optimization** - Instant theme switching, smooth animations
- **Code Organization** - Maintainable, scalable architecture
- **Production Readiness** - Robust error handling and user feedback

## 🐳 Docker Deployment

### **Quick Start with Docker Compose**

1. **Clone and setup:**

   ```bash
   git clone <your-repo>
   cd todo_app
   cp .env.example .env
   # Edit .env with your Stripe keys
   ```

2. **Launch with Docker:**

   ```bash
   docker-compose up --build
   ```

3. **Access your app:**
   - **App**: http://localhost:3000

That's it! The app uses SQLite (file-based database) so no separate database setup needed.

### **Production Deployment**

For production deployment, use the included Dockerfile with Kamal:

```bash
# Build and deploy
kamal deploy
```

### **Environment Variables**

Required environment variables (copy from `.env.example`):

```bash
# Stripe (required for payments)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

---

**"Do it" represents a complete, production-ready Rails application with professional-grade features, beautiful design, and exceptional user experience. It's a testament to modern Rails development and thoughtful UI/UX design.**
