# Rails Todo App - Step-by-Step Execution Guide (UPDATED)

**Purpose:** A beginner-friendly execution guide with detailed explanations for building a simple Rails 8.0.2 todo application using SQLite and basic deployment.

## 🎉 CURRENT STATUS: AUTHENTICATION COMPLETE!

**✅ COMPLETED PHASES:**

- Phase 1: Foundation Setup ✅
- Phase 2: Basic Models & CRUD ✅
- Phase 3: User Authentication ✅

**🚀 NEXT UP:** Edit/Delete Functionality (CRUD Completion)

## 📋 DETAILED PROGRESS TRACKER

### ✅ Phase 1: Foundation Setup (COMPLETE)

- [x] Rails app created with Tailwind CSS
- [x] Database models (User, Project, Todo)
- [x] Basic relationships established
- [x] Tailwind CSS configured and working
- [x] Basic routes and controllers

### ✅ Phase 2: Basic CRUD Operations (COMPLETE)

- [x] Projects: Create, Read (index, show)
- [x] Todos: Create, Read, Toggle completion
- [x] Beautiful UI with Tailwind
- [x] Flash messages for user feedback
- [x] Form validation and error handling

### ✅ Phase 3: User Authentication (COMPLETE)

- [x] bcrypt gem installed and configured
- [x] User model with has_secure_password
- [x] SessionsController (login/logout)
- [x] RegistrationsController (signup)
- [x] Authentication routes configured
- [x] Login/signup forms with Tailwind styling
- [x] Navigation header with user status
- [x] Controller protection (before_action :require_login)
- [x] User data isolation (current_user.projects)
- [x] Proper Turbo integration for logout

### 🚧 Phase 4: Complete CRUD Operations (NEXT)

- [ ] Edit projects (form, update action, validation)
- [ ] Delete projects (confirmation, cascade delete todos)
- [ ] Edit todos (inline or modal editing)
- [ ] Delete todos (with confirmation)
- [ ] Proper error handling and flash messages

### 🔮 Phase 5: Advanced Features (FUTURE)

- [ ] Todo reordering/positioning
- [ ] Project colors and themes
- [ ] Due dates for todos
- [ ] Search and filtering
- [ ] Deployment to production

---

## Prerequisites Check

Before we start, let's verify your development environment:

```bash
# Check Ruby version (should be >= 3.1.0 for Rails 8.0.2)
ruby --version

# Check if Rails is installed (if not, install with: gem install rails)
rails --version
```

**Learning Note:** Rails 8.0.2 requires Ruby 3.1+ and comes with everything we need built-in, including SQLite for the database. We'll keep things simple and use the defaults.

---

## ✅ COMPLETED: Phase 1: Foundation Setup (Days 1-2)

### Step 1: Create the Rails Application

```bash
# Create new Rails app with Tailwind CSS and SQLite3
rails new todo_app --css=tailwind --database=sqlite3 --skip-test

cd todo_app
```

**Learning Explanation:**

- `--css=tailwind`: Automatically configures Tailwind CSS with the Rails asset pipeline
- `--database=sqlite3`: Uses SQLite for both development and production (simple and reliable)
- `--skip-test`: We'll set up basic testing later to understand the process

**What Rails Created:**

```
todo_app/
├── app/                    # Main application code
│   ├── controllers/       # Handle HTTP requests
│   ├── models/           # Data layer and business logic
│   ├── views/            # HTML templates
│   └── assets/           # CSS, JS, images
├── config/               # Application configuration
├── db/                   # Database files and migrations
├── Gemfile               # Ruby gem dependencies
└── config.ru             # Rack configuration for web server
```

### Step 2: Initial Database Setup

```bash
# Create the database and run any initial migrations
bin/rails db:create
bin/rails db:migrate
```

**Learning Note:** `bin/rails` uses the Rails executable bundled with your app, ensuring version consistency. Always use `bin/rails` instead of global `rails` command in projects.

### Step 3: Verify Tailwind Integration

```bash
# Start the Rails server
bin/rails server
```

Open http://localhost:3000 in your browser. You should see the Rails welcome page.

**Test Tailwind:** Create a simple test page to verify Tailwind is working:

```bash
# Generate a simple controller to test styling
bin/rails generate controller Welcome index
```

Edit `app/views/welcome/index.html.erb`:

```erb
<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
  <div class="bg-white p-8 rounded-xl shadow-lg">
    <h1 class="text-3xl font-bold text-gray-800 mb-4">Welcome to Todo App!</h1>
    <p class="text-gray-600">Tailwind CSS is working correctly.</p>
  </div>
</div>
```

Update `config/routes.rb` to set this as root:

```ruby
Rails.application.routes.draw do
  root 'welcome#index'
  # Other routes will go here
end
```

**Learning Note:** This test verifies that Tailwind's utility classes are being processed and applied correctly.

---

## Phase 2: Core Models and Database Design (Days 2-3)

### Step 4: Generate Core Models

```bash
# Generate User model (will be enhanced by authentication generator)
bin/rails generate model User email_address:string

# Generate Project model
bin/rails generate model Project name:string description:text cover_color:string user:references

# Generate Todo model
bin/rails generate model Todo title:string notes:text completed:boolean project:references position:integer

# Run the migrations
bin/rails db:migrate
```

**Learning Explanation - Migrations:**
Each `generate model` command creates:

1. **Model file** (`app/models/user.rb`) - Contains business logic and relationships
2. **Migration file** (`db/migrate/xxx_create_users.rb`) - Database schema changes
3. **Test files** (we skipped these but they're normally created)

Let's look at what was generated:

```ruby
# db/migrate/xxx_create_projects.rb
class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :cover_color
      t.references :user, null: false, foreign_key: true  # Creates user_id column with foreign key constraint

      t.timestamps  # Automatically adds created_at and updated_at
    end
  end
end
```

**Key Learning Points:**

- `t.references :user` creates a `user_id` column and sets up the foreign key relationship
- `foreign_key: true` ensures referential integrity at the database level
- `null: false` means this field is required (every project must belong to a user)

### Step 5: Set Up Model Relationships and Validations

Edit `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  # Authentication will be added by the generator in next phase
  has_many :projects, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

Edit `app/models/project.rb`:

```ruby
class Project < ApplicationRecord
  belongs_to :user
  has_many :todos, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :user, presence: true

  scope :ordered, -> { order(:created_at) }

  def completed_todos_count
    todos.where(completed: true).count
  end

  def total_todos_count
    todos.count
  end

  def completion_percentage
    return 0 if total_todos_count == 0
    (completed_todos_count.to_f / total_todos_count * 100).round
  end
end
```

Edit `app/models/todo.rb`:

```ruby
class Todo < ApplicationRecord
  belongs_to :project

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :project, presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :ordered, -> { order(:position) }

  before_create :set_position

  def toggle_completion!
    update!(completed: !completed)
  end

  private

  def set_position
    self.position ||= (project.todos.maximum(:position) || 0) + 1
  end
end
```

**Learning Explanation - Active Record Patterns:**

1. **Validations**: Ensure data integrity at the application level

   - `presence: true` - Field cannot be blank
   - `uniqueness: true` - No duplicates allowed
   - `length:` - String length constraints
   - `format:` - Regex pattern matching

2. **Associations**: Define relationships between models

   - `belongs_to` - This model has a foreign key to another
   - `has_many` - This model is referenced by many others
   - `dependent: :destroy` - Delete associated records when parent is deleted

3. **Scopes**: Reusable query methods

   - `scope :completed` creates `Todo.completed` method
   - Chainable: `project.todos.completed.ordered`

4. **Callbacks**: Methods that run at specific times
   - `before_create :set_position` runs before saving new records

### Step 6: Test Your Models in Rails Console

```bash
# Open Rails console to test your models
bin/rails console
```

In the console, try these commands:

```ruby
# Create a test user
user = User.create!(email_address: "test@example.com")

# Create a project for this user
project = user.projects.create!(name: "My First Project", description: "Learning Rails!")

# Create some todos
todo1 = project.todos.create!(title: "Learn Rails MVC pattern")
todo2 = project.todos.create!(title: "Build authentication system")
todo3 = project.todos.create!(title: "Deploy to production")

# Test relationships
puts "User has #{user.projects.count} projects"
puts "Project has #{project.todos.count} todos"

# Test scopes and methods
todo1.toggle_completion!
puts "Completed todos: #{project.todos.completed.count}"
puts "Project completion: #{project.completion_percentage}%"

# Exit console
exit
```

**Learning Note:** The Rails console is your best friend for testing models, debugging, and exploring your data. Always test your models here before building controllers and views.

---

## Phase 3: Authentication System (Days 3-4)

### Step 7: Set Up Authentication with authentication-zero

Rails 8.0.2 doesn't have built-in authentication, so we'll use the Rails team's recommended `authentication-zero` gem.

```bash
# Add authentication-zero gem
bundle add authentication-zero

# Generate authentication system
bin/rails generate authentication
bin/rails db:migrate
```

**What This Generator Creates:**

1. **Updates User Model** with authentication:

```ruby
# app/models/user.rb (updated)
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :projects, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
```

2. **Session Model** for tracking user sessions:

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user

  before_create do
    self.token = SecureRandom.base58(32)
  end
end
```

3. **Authentication Controllers**:

   - `SessionsController` - Handle login/logout
   - `PasswordsController` - Handle password reset

4. **Application Controller Updates**:

```ruby
# app/controllers/application_controller.rb (updated)
class ApplicationController < ActionController::Base
  before_action :require_authenticated_user!

  private

  def require_authenticated_user!
    redirect_to new_session_path unless authenticated?
  end

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_token] = { value: session.token, httponly: true }
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
  end
end
```

**Learning Explanation - Authentication Concepts:**

- **has_secure_password**: Rails method that handles password hashing with bcrypt
- **Sessions**: Server-side records of user authentication state
- **Cookies**: Client-side tokens that identify the session
- **Current**: Rails 8 pattern for thread-safe current user tracking

### Step 8: Add User Registration (Sign-up)

The generator doesn't include registration, so we'll add it:

```bash
# Generate registrations controller
bin/rails generate controller Registrations new create
```

Edit `app/controllers/registrations_controller.rb`:

```ruby
class RegistrationsController < ApplicationController
  # Allow unauthenticated access to registration pages
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: 'Welcome! Your account was created successfully.'
    else
      flash.now[:alert] = 'There was a problem creating your account.'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
```

Create the registration form `app/views/registrations/new.html.erb`:

```erb
<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
  <div class="bg-white p-8 rounded-xl shadow-lg w-full max-w-md">
    <h1 class="text-2xl font-bold text-gray-800 mb-6 text-center">Create Your Account</h1>

    <%= form_with model: @user, url: sign_up_path, local: true, class: "space-y-4" do |form| %>
      <% if @user.errors.any? %>
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          <ul class="list-disc list-inside">
            <% @user.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <div>
        <%= form.label :email_address, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= form.email_field :email_address,
            class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "your@email.com" %>
      </div>

      <div>
        <%= form.label :password, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= form.password_field :password,
            class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "Choose a secure password" %>
      </div>

      <div>
        <%= form.label :password_confirmation, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= form.password_field :password_confirmation,
            class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "Confirm your password" %>
      </div>

      <div>
        <%= form.submit "Create Account",
            class: "w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors" %>
      </div>
    <% end %>

    <p class="mt-4 text-center text-sm text-gray-600">
      Already have an account?
      <%= link_to "Sign in", new_session_path, class: "text-blue-600 hover:text-blue-800" %>
    </p>
  </div>
</div>
```

Update `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Authentication routes
  resource :session, only: [:new, :create, :destroy]
  resources :passwords, only: [:new, :create, :edit, :update], param: :token
  resource :sign_up, controller: :registrations, only: [:new, :create]

  # Application routes
  resources :projects do
    resources :todos, except: [:show]
  end

  root 'projects#index'
end
```

### Step 9: Update Session Views

The generator creates basic session views. Let's style the login form:

Edit `app/views/sessions/new.html.erb`:

```erb
<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
  <div class="bg-white p-8 rounded-xl shadow-lg w-full max-w-md">
    <h1 class="text-2xl font-bold text-gray-800 mb-6 text-center">Sign In</h1>

    <%= form_with url: session_path, local: true, class: "space-y-4" do |form| %>
      <div>
        <%= form.label :email_address, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= form.email_field :email_address,
            class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "your@email.com" %>
      </div>

      <div>
        <%= form.label :password, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= form.password_field :password,
            class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
            placeholder: "Your password" %>
      </div>

      <div>
        <%= form.submit "Sign In",
            class: "w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors" %>
      </div>
    <% end %>

    <div class="mt-4 text-center space-y-2">
      <p class="text-sm text-gray-600">
        Don't have an account?
        <%= link_to "Sign up", sign_up_path, class: "text-blue-600 hover:text-blue-800" %>
      </p>
      <p class="text-sm text-gray-600">
        <%= link_to "Forgot your password?", new_password_path, class: "text-blue-600 hover:text-blue-800" %>
      </p>
    </div>
  </div>
</div>
```

**Learning Note:** The authentication system uses Rails' `form_with` helper, which automatically includes CSRF tokens for security. The `local: true` option ensures forms submit as regular HTTP requests rather than AJAX.

---

## Phase 4: Core Application Features (Days 4-6)

### Step 10: Generate Controllers for Projects and Todos

```bash
# Generate controllers with basic actions
bin/rails generate controller Projects index show new create edit update destroy
bin/rails generate controller Todos index new create edit update destroy
```

### Step 11: Implement Projects Controller

Edit `app/controllers/projects_controller.rb`:

```ruby
class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    @projects = current_user.projects.ordered.includes(:todos)
  end

  def show
    @todos = @project.todos.ordered
    @new_todo = @project.todos.build
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: 'Project was successfully deleted.'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :cover_color)
  end
end
```

**Learning Explanation - Controller Patterns:**

1. **before_action**: Runs methods before specified actions
2. **Scoping to current_user**: `current_user.projects` ensures users only see their own data
3. **includes(:todos)**: Prevents N+1 queries by loading associated todos
4. **Strong Parameters**: `project_params` method whitelist allowed form fields
5. **Status Codes**: `:unprocessable_entity` (422) for validation errors

### Step 12: Implement Todos Controller

Edit `app/controllers/todos_controller.rb`:

```ruby
class TodosController < ApplicationController
  before_action :set_project
  before_action :set_todo, only: [:show, :edit, :update, :destroy]

  def index
    redirect_to @project
  end

  def new
    @todo = @project.todos.build
  end

  def create
    @todo = @project.todos.build(todo_params)

    if @todo.save
      redirect_to @project, notice: 'Todo was successfully created.'
    else
      @todos = @project.todos.ordered
      render 'projects/show', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      if params[:todo][:completed].present?
        # Handle AJAX toggle requests
        head :ok
      else
        redirect_to @project, notice: 'Todo was successfully updated.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    redirect_to @project, notice: 'Todo was successfully deleted.'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_todo
    @todo = @project.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position)
  end
end
```

**Learning Note:** Nested resources (todos under projects) use both `project_id` and `id` parameters. The `set_project` method ensures todos are always scoped to the correct project.

### Step 13: Create Project Views

Create `app/views/projects/index.html.erb`:

```erb
<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">My Projects</h1>
        <p class="text-gray-600 mt-1">Organize your todos into projects</p>
      </div>

      <div class="flex items-center space-x-4">
        <span class="text-sm text-gray-600">Welcome, <%= current_user.email_address %></span>
        <%= link_to "Sign out", session_path, method: :delete,
            class: "text-sm text-red-600 hover:text-red-800" %>
      </div>
    </div>

    <!-- New Project Button -->
    <div class="mb-8">
      <%= link_to new_project_path,
          class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500" do %>
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
        </svg>
        New Project
      <% end %>
    </div>

    <!-- Projects Grid -->
    <% if @projects.any? %>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <% @projects.each do |project| %>
          <div class="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-gray-900">
                  <%= link_to project.name, project, class: "hover:text-blue-600" %>
                </h3>
                <% if project.cover_color.present? %>
                  <div class="w-4 h-4 rounded-full" style="background-color: <%= project.cover_color %>"></div>
                <% end %>
              </div>

              <% if project.description.present? %>
                <p class="text-gray-600 text-sm mb-4 line-clamp-2"><%= project.description %></p>
              <% end %>

              <!-- Project Stats -->
              <div class="flex items-center justify-between text-sm text-gray-500">
                <span><%= project.total_todos_count %> todos</span>
                <span><%= project.completion_percentage %>% complete</span>
              </div>

              <!-- Progress Bar -->
              <div class="mt-3 bg-gray-200 rounded-full h-2">
                <div class="bg-green-500 h-2 rounded-full transition-all duration-300"
                     style="width: <%= project.completion_percentage %>%"></div>
              </div>

              <!-- Actions -->
              <div class="mt-4 flex justify-end space-x-2">
                <%= link_to "Edit", edit_project_path(project),
                    class: "text-blue-600 hover:text-blue-800 text-sm" %>
                <%= link_to "Delete", project_path(project), method: :delete,
                    confirm: "Are you sure?",
                    class: "text-red-600 hover:text-red-800 text-sm" %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    <% else %>
      <!-- Empty State -->
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">No projects yet</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by creating your first project.</p>
        <div class="mt-6">
          <%= link_to "Create Project", new_project_path,
              class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700" %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

Create `app/views/projects/show.html.erb`:

```erb
<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
    <!-- Project Header -->
    <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center space-x-4">
          <%= link_to projects_path, class: "text-gray-400 hover:text-gray-600" do %>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
          <% end %>

          <div>
            <h1 class="text-2xl font-bold text-gray-900"><%= @project.name %></h1>
            <% if @project.description.present? %>
              <p class="text-gray-600 mt-1"><%= @project.description %></p>
            <% end %>
          </div>
        </div>

        <div class="flex items-center space-x-2">
          <%= link_to "Edit Project", edit_project_path(@project),
              class: "text-blue-600 hover:text-blue-800 text-sm" %>
          <%= link_to "Delete Project", project_path(@project), method: :delete,
              confirm: "Are you sure? This will delete all todos in this project.",
              class: "text-red-600 hover:text-red-800 text-sm" %>
        </div>
      </div>

      <!-- Project Stats -->
      <div class="flex items-center space-x-6 text-sm text-gray-500">
        <span><%= @project.total_todos_count %> todos</span>
        <span><%= @project.completed_todos_count %> completed</span>
        <span><%= @project.completion_percentage %>% complete</span>
      </div>

      <!-- Progress Bar -->
      <div class="mt-3 bg-gray-200 rounded-full h-2">
        <div class="bg-green-500 h-2 rounded-full transition-all duration-300"
             style="width: <%= @project.completion_percentage %>%"></div>
      </div>
    </div>

    <!-- Add New Todo -->
    <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Add New Todo</h2>

      <%= form_with model: [@project, @new_todo], local: true, class: "space-y-4" do |form| %>
        <% if @new_todo.errors.any? %>
          <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            <ul class="list-disc list-inside">
              <% @new_todo.errors.full_messages.each do |message| %>
                <li><%= message %></li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div class="flex space-x-4">
          <div class="flex-1">
            <%= form.text_field :title,
                class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
                placeholder: "What needs to be done?" %>
          </div>

          <div>
            <%= form.submit "Add Todo",
                class: "px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
          </div>
        </div>

        <div>
          <%= form.text_area :notes,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
              placeholder: "Additional notes (optional)", rows: 2 %>
        </div>
      <% end %>
    </div>

    <!-- Todos List -->
    <div class="bg-white rounded-lg shadow-sm">
      <div class="p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          Todos
          <span class="text-sm font-normal text-gray-500">(<%= @todos.count %>)</span>
        </h2>

        <% if @todos.any? %>
          <div class="space-y-3">
            <% @todos.each do |todo| %>
              <div class="flex items-start space-x-3 p-3 border border-gray-200 rounded-lg hover:bg-gray-50">
                <!-- Checkbox -->
                <%= form_with model: [@project, todo], method: :patch, local: true,
                    class: "flex items-center" do |form| %>
                  <%= form.check_box :completed,
                      class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded",
                      onchange: "this.form.submit()" %>
                <% end %>

                <!-- Todo Content -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <h4 class="text-sm font-medium text-gray-900 <%= 'line-through text-gray-500' if todo.completed %>">
                      <%= todo.title %>
                    </h4>

                    <div class="flex items-center space-x-2">
                      <%= link_to "Edit", edit_project_todo_path(@project, todo),
                          class: "text-blue-600 hover:text-blue-800 text-xs" %>
                      <%= link_to "Delete", project_todo_path(@project, todo), method: :delete,
                          confirm: "Are you sure?",
                          class: "text-red-600 hover:text-red-800 text-xs" %>
                    </div>
                  </div>

                  <% if todo.notes.present? %>
                    <p class="mt-1 text-sm text-gray-600 <%= 'line-through' if todo.completed %>">
                      <%= todo.notes %>
                    </p>
                  <% end %>

                  <p class="mt-1 text-xs text-gray-400">
                    Position: <%= todo.position %>
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <!-- Empty State -->
          <div class="text-center py-8">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No todos yet</h3>
            <p class="mt-1 text-sm text-gray-500">Add your first todo to get started!</p>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

**Learning Note:** This view demonstrates several Rails patterns:

- **Nested forms**: `[@project, @new_todo]` creates the correct nested route
- **Conditional styling**: Using Ruby conditionals in CSS classes
- **Form helpers**: `form_with` generates proper form tags and CSRF tokens
- **Partials potential**: This could be refactored into smaller partial templates

### Step 14: Create Project Form Views

Create `app/views/projects/new.html.erb`:

```erb
<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="bg-white rounded-lg shadow-sm p-8">
      <div class="mb-6">
        <%= link_to projects_path, class: "text-gray-400 hover:text-gray-600 inline-flex items-center" do %>
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
          </svg>
          Back to Projects
        <% end %>
      </div>

      <h1 class="text-2xl font-bold text-gray-900 mb-6">Create New Project</h1>

      <%= form_with model: @project, local: true, class: "space-y-6" do |form| %>
        <% if @project.errors.any? %>
          <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            <h4 class="font-semibold">Please fix the following errors:</h4>
            <ul class="list-disc list-inside mt-2">
              <% @project.errors.full_messages.each do |message| %>
                <li><%= message %></li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div>
          <%= form.label :name, class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= form.text_field :name,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
              placeholder: "e.g., Work Tasks, Personal Goals, Learning" %>
        </div>

        <div>
          <%= form.label :description, class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= form.text_area :description,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
              placeholder: "What is this project about? (optional)", rows: 3 %>
        </div>

        <div>
          <%= form.label :cover_color, "Project Color", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <div class="flex items-center space-x-2">
            <%= form.color_field :cover_color,
                class: "h-10 w-20 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500",
                value: @project.cover_color || "#3B82F6" %>
            <span class="text-sm text-gray-500">Choose a color to identify your project</span>
          </div>
        </div>

        <div class="flex justify-end space-x-4">
          <%= link_to "Cancel", projects_path,
              class: "px-4 py-2 text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500" %>
          <%= form.submit "Create Project",
              class: "px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

Create `app/views/projects/edit.html.erb` (similar structure, just change the title and submit button text).

### Step 15: Test the Basic Application

```bash
# Start the server
bin/rails server
```

Now you can test:

1. Visit http://localhost:3000
2. Sign up for a new account
3. Create a project
4. Add some todos
5. Mark todos as complete
6. Test editing and deleting

**Learning Checkpoint:** At this point, you have a fully functional Rails application with:

- User authentication and registration
- Project and todo management
- Proper data scoping (users only see their own data)
- Clean, responsive UI with Tailwind CSS

---

## Phase 5: Basic Styling Improvements (Days 6-7)

### Step 16: Add Simple Custom Styles

Let's add some basic custom styles to make our app look more polished. Add to `app/assets/stylesheets/application.tailwind.css`:

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Simple custom styles */
@layer components {
  .btn-primary {
    @apply bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors;
  }

  .btn-secondary {
    @apply bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 transition-colors;
  }

  .card {
    @apply bg-white rounded-lg shadow-md p-6;
  }

  .form-input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500;
  }
}
```

### Step 17: Update Views to Use Custom Styles

Now let's update our views to use the custom CSS classes we created. This will make our code cleaner and more maintainable.

Update the form buttons in your views to use the new classes:

```erb
<!-- Instead of long Tailwind classes, use: -->
<%= form.submit "Create Project", class: "btn-primary" %>
<%= link_to "Cancel", projects_path, class: "btn-secondary" %>

<!-- For form inputs, use: -->
<%= form.text_field :name, class: "form-input", placeholder: "Project name" %>

<!-- For cards, use: -->
<div class="card">
  <!-- content here -->
</div>
```

**Learning Note:** At this point, you have a clean, functional Rails application with:

- Simple, maintainable styling using Tailwind CSS
- Reusable CSS component classes
- Clean, responsive user interface
- Good separation of concerns between styling and functionality

This approach keeps your code organized and makes it easy to maintain and update your styles consistently across the application.

---

## Phase 6: Basic Testing (Day 7)

### Step 18: Set Up Simple Testing

Rails comes with a built-in testing framework. Let's add just a few basic tests to ensure our app works:

```bash
# Generate basic test files
bin/rails generate test_unit:model user
bin/rails generate test_unit:model project
bin/rails generate test_unit:model todo
```

### Step 19: Write Basic Model Tests

Let's write a simple test to make sure our User model works correctly. Edit `test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(password: "password123")
    assert_not user.save, "Saved user without an email address"
  end

  test "should not save user with duplicate email" do
    User.create!(email_address: "test@example.com", password: "password123")
    duplicate_user = User.new(email_address: "test@example.com", password: "password123")
    assert_not duplicate_user.save, "Saved user with duplicate email"
  end

  test "should save valid user" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert user.save, "Could not save valid user"
  end
end
```

Edit `test/models/project_test.rb`:

```ruby
require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "should not save project without name" do
    user = User.create!(email_address: "test@example.com", password: "password123")
    project = user.projects.build(name: "")
    assert_not project.save, "Saved project without a name"
  end

  test "should calculate completion percentage" do
    user = User.create!(email_address: "test@example.com", password: "password123")
    project = user.projects.create!(name: "Test Project")

    project.todos.create!(title: "Todo 1", completed: true)
    project.todos.create!(title: "Todo 2", completed: false)

    assert_equal 50, project.completion_percentage
  end
end
```

### Step 20: Run Your Tests

Now let's run our simple tests to make sure everything works:

```bash
# Run all tests
bin/rails test

# Run specific test files
bin/rails test test/models/user_test.rb
bin/rails test test/models/project_test.rb
```

If your tests pass, great! If not, check that your models have the proper validations and associations as defined earlier in this guide.

**Learning Note:** Testing is crucial for maintaining code quality as your application grows. These basic model tests ensure your core business logic works correctly and will catch errors when you make changes later.

---

## Phase 7: Simple Deployment (Day 8)

### Step 21: Prepare for Production

Rails comes with good production defaults, but let's make a few small tweaks. First, ensure your `config/environments/production.rb` has these settings:

```ruby
# In config/environments/production.rb, make sure these are set:
config.force_ssl = true  # Redirect HTTP to HTTPS
config.log_level = :info  # Don't log debug info in production
```

### Step 22: Deploy to Heroku (Simple Option)

Heroku is the easiest way to deploy a Rails app. Here's how:

1. **Install the Heroku CLI** and create an account at heroku.com

2. **Prepare your app for Heroku:**

```bash
# Add a Procfile to tell Heroku how to start your app
echo "web: bundle exec puma -C config/puma.rb" > Procfile

# Heroku uses PostgreSQL, so add the pg gem for production only
echo "gem 'pg', '~> 1.1', group: :production" >> Gemfile
bundle install
```

3. **Deploy to Heroku:**

```bash
# Initialize git if you haven't already
git init
git add .
git commit -m "Initial commit"

# Create Heroku app
heroku create your-todo-app-name

# Deploy
git push heroku main

# Run database migrations on Heroku
heroku run rails db:migrate

# Open your app
heroku open
```

### Step 23: Alternative Deployment Options

If you prefer other hosting options, here are some beginner-friendly alternatives:

**Option 1: Railway**

- Similar to Heroku but with more generous free tier
- Visit railway.app, connect your GitHub repo, and deploy with one click

**Option 2: Render**

- Free hosting for static sites and web services
- Visit render.com, connect your repo, and follow their Rails deployment guide

**Learning Note:** The beauty of Rails is that it runs anywhere. Once you understand the basics of deployment (environment variables, database setup, asset compilation), you can deploy to any hosting provider.

---

## Troubleshooting Guide

### Common Issues and Solutions

**Issue: Tailwind styles not loading**

```bash
# Restart the Rails server and check if Tailwind is watching for changes
bin/rails server
```

**Issue: Authentication not working**

```bash
# Check in Rails console if your User model is set up correctly
bin/rails console
User.first.authenticate("password123")
```

**Issue: Database relationship errors**

```bash
# Check your associations in Rails console
bin/rails console
user = User.first
user.projects
```

**Issue: Tests failing**

```bash
# Make sure your test database is set up
bin/rails db:test:prepare
bin/rails test
```

---

## Final Learning Summary

Congratulations! You've built a complete Rails application with authentication, clean UI, and deployment knowledge. Here's what you've learned:

### Core Rails Concepts You Now Understand

- **MVC Architecture**: How controllers, models, and views work together
- **Active Record**: Database relationships, validations, and queries
- **Routing**: RESTful routes and nested resources for related data
- **Authentication**: User registration, login, and session management
- **Styling**: Using Tailwind CSS with Rails for responsive design
- **Testing**: Writing basic tests to ensure your code works
- **Deployment**: Getting your app online for others to use

### Key Skills You've Developed

- **Problem-solving**: Breaking down features into manageable steps
- **Rails conventions**: Following Rails' "convention over configuration" philosophy
- **Database design**: Creating proper relationships between your data models
- **User experience**: Building forms, navigation, and feedback for users
- **Code organization**: Keeping your code clean and maintainable

### What You Can Build Next

Now that you understand the fundamentals, you can:

1. **Add new features**: Search, categories, due dates, file uploads
2. **Improve the design**: Custom themes, better mobile experience
3. **Add collaboration**: Share projects with other users
4. **Learn more Rails**: Background jobs, email sending, APIs

You now have a solid foundation in Rails development and the confidence to build web applications!

---

## Additional Resources

- **Rails Guides**: https://guides.rubyonrails.org/ - The official Rails documentation
- **Rails Tutorial**: https://railstutorial.org/ - Michael Hartl's comprehensive Rails book
- **Tailwind CSS**: https://tailwindcss.com/docs - Complete CSS framework documentation
- **Heroku Rails Guide**: https://devcenter.heroku.com/articles/getting-started-with-rails8 - Deployment help
- **Ruby on Rails Community**: https://rubyonrails.org/community - Forums and help

**Learning Path Suggestions:**

1. Complete this todo app with all the features
2. Try building a different app (blog, recipe manager, etc.)
3. Learn about Rails APIs and build a mobile app backend
4. Explore advanced Rails features like Action Cable for real-time features
