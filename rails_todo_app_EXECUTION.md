# Rails Todo App - Step-by-Step Execution Guide

**Purpose:** A comprehensive, beginner-friendly execution guide with detailed explanations, code examples, and learning notes for building a Rails 8.2 todo application.

---

## Prerequisites Check

Before we start, let's verify your development environment:

```bash
# Check Ruby version (should be >= 3.1.0 for Rails 8.2)
ruby --version

# Check if Rails is installed
rails --version

# Check if Node.js is available (needed for Tailwind)
node --version

# Check if Yarn or npm is available
yarn --version
# OR
npm --version
```

**Learning Note:** Rails 8.0.2 requires Ruby 3.1+ because it uses newer Ruby features for better performance and security. Rails 8.0 introduces Solid gems (Queue, Cache, Cable) replacing Redis for many use cases.

---

## Phase 1: Foundation Setup (Days 1-2)

### Step 1: Create the Rails Application

```bash
# Create new Rails app with Tailwind CSS and SQLite3
rails new todo_app --css=tailwind --database=sqlite3 --skip-test

cd todo_app
```

**Learning Explanation:**

- `--css=tailwind`: Automatically configures Tailwind CSS with the Rails asset pipeline
- `--database=sqlite3`: Uses SQLite for development (we'll switch to PostgreSQL for production)
- `--skip-test`: We'll set up testing manually to understand the process better

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

## Phase 5: Advanced Styling and User Experience (Days 6-8)

### Step 16: Add Handwritten Font and Dotted Background

Add to `app/views/layouts/application.html.erb` in the `<head>` section:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Gloria+Hallelujah&family=Kalam:wght@300;400;700&display=swap" rel="stylesheet">
```

Update `tailwind.config.js`:

```js
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./public/*.html",
    "./app/**/*.{js,jsx,ts,tsx,vue,erb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      fontFamily: {
        handwriting: ["Gloria Hallelujah", "cursive"],
        casual: ["Kalam", "cursive"],
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      animation: {
        "write-in": "write-in 2s ease-out forwards",
        "fade-in": "fade-in 0.5s ease-out forwards",
        "bounce-in": "bounce-in 0.6s ease-out forwards",
      },
      keyframes: {
        "write-in": {
          "0%": { width: "0%", opacity: "0" },
          "50%": { opacity: "1" },
          "100%": { width: "100%", opacity: "1" },
        },
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "bounce-in": {
          "0%": { opacity: "0", transform: "scale(0.3)" },
          "50%": { opacity: "1", transform: "scale(1.05)" },
          "70%": { transform: "scale(0.9)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
```

Add custom styles to `app/assets/stylesheets/application.tailwind.css`:

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Dotted background pattern */
@layer base {
  body {
    background-image: radial-gradient(circle, #e5e7eb 1px, transparent 1px);
    background-size: 20px 20px;
    font-family: "Kalam", cursive;
  }

  /* Override for specific elements */
  .font-handwriting {
    font-family: "Gloria Hallelujah", cursive;
  }
}

/* Custom checkbox styles */
@layer components {
  .custom-checkbox {
    @apply relative inline-block w-6 h-6 cursor-pointer;
  }

  .custom-checkbox input {
    @apply sr-only;
  }

  .custom-checkbox svg {
    @apply w-full h-full transition-all duration-200;
  }

  .custom-checkbox input:checked + svg .checkbox-tick {
    stroke-dasharray: 20;
    stroke-dashoffset: 0;
    animation: draw-tick 0.5s ease-out forwards;
  }

  .custom-checkbox svg .checkbox-tick {
    stroke-dasharray: 20;
    stroke-dashoffset: 20;
  }

  @keyframes draw-tick {
    to {
      stroke-dashoffset: 0;
    }
  }
}

/* Write-in effect for new todos */
@layer components {
  .write-in-effect {
    overflow: hidden;
    border-right: 2px solid #3b82f6;
    white-space: nowrap;
    animation: typing 2s steps(40, end), blink-caret 0.75s step-end infinite;
  }

  @keyframes typing {
    from {
      width: 0;
    }
    to {
      width: 100%;
    }
  }

  @keyframes blink-caret {
    from,
    to {
      border-color: transparent;
    }
    50% {
      border-color: #3b82f6;
    }
  }
}

/* Hand-drawn style elements */
@layer components {
  .hand-drawn-border {
    border: 2px solid #374151;
    border-radius: 8px;
    position: relative;
  }

  .hand-drawn-border::before {
    content: "";
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    border: 2px solid #374151;
    border-radius: 8px;
    transform: rotate(0.5deg);
    z-index: -1;
  }
}
```

### Step 17: Create Custom Checkbox Component

Create `app/views/shared/_custom_checkbox.html.erb`:

```erb
<label class="custom-checkbox">
  <%= check_box_tag name, value, checked,
      { class: "sr-only",
        onchange: onchange_js,
        data: { todo_id: todo_id } } %>

  <svg viewBox="0 0 24 24" class="text-gray-600 hover:text-blue-600 transition-colors">
    <!-- Hand-drawn style checkbox -->
    <path d="M3 5c0-1.1.9-2 2-2h14c1.1 0 2 .9 2 2v14c0 1.1-.9 2-2 2H5c-1.1 0-2-.9-2-2V5z"
          stroke="currentColor"
          stroke-width="2"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="checkbox-box"/>

    <!-- Animated checkmark -->
    <path d="M7 12l3 3 7-7"
          stroke="currentColor"
          stroke-width="2.5"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="checkbox-tick <%= 'opacity-100' if checked %> <%= 'opacity-0' unless checked %>"/>
  </svg>
</label>
```

### Step 18: Add Stimulus Controller for Interactive Features

Create `app/javascript/controllers/todo_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "title", "notes"];
  static values = {
    projectId: Number,
    todoId: Number,
    completed: Boolean,
  };

  connect() {
    // Add animation class when controller connects
    if (this.element.dataset.newTodo === "true") {
      this.animateIn();
    }
  }

  toggle(event) {
    const checkbox = event.target;
    const isCompleted = checkbox.checked;

    // Animate the change
    this.animateToggle(isCompleted);

    // Submit the form via AJAX
    this.submitToggle(isCompleted);
  }

  animateToggle(isCompleted) {
    const title = this.titleTarget;
    const notes = this.hasNotesTarget ? this.notesTarget : null;

    if (isCompleted) {
      title.classList.add(
        "line-through",
        "text-gray-500",
        "transition-all",
        "duration-300"
      );
      if (notes) notes.classList.add("line-through", "text-gray-400");
    } else {
      title.classList.remove("line-through", "text-gray-500");
      if (notes) notes.classList.remove("line-through", "text-gray-400");
    }
  }

  animateIn() {
    this.element.classList.add("animate-fade-in");

    // Remove the data attribute so it doesn't animate again
    setTimeout(() => {
      this.element.removeAttribute("data-new-todo");
    }, 500);
  }

  submitToggle(isCompleted) {
    const form = new FormData();
    form.append("todo[completed]", isCompleted);
    form.append("_method", "PATCH");

    // Get CSRF token
    const token = document.querySelector('meta[name="csrf-token"]').content;

    fetch(`/projects/${this.projectIdValue}/todos/${this.todoIdValue}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "X-Requested-With": "XMLHttpRequest",
      },
      body: form,
    })
      .then((response) => {
        if (!response.ok) {
          // Revert the checkbox if the request failed
          const checkbox = this.checkboxTarget;
          checkbox.checked = !isCompleted;
          this.animateToggle(!isCompleted);
        }
      })
      .catch((error) => {
        console.error("Error updating todo:", error);
        // Revert the checkbox
        const checkbox = this.checkboxTarget;
        checkbox.checked = !isCompleted;
        this.animateToggle(!isCompleted);
      });
  }
}
```

Create `app/javascript/controllers/typing_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    text: String,
    speed: { type: Number, default: 50 },
  };

  connect() {
    this.typeText();
  }

  typeText() {
    const text = this.textValue || this.element.textContent;
    const speed = this.speedValue;

    // Clear the element
    this.element.textContent = "";
    this.element.classList.add("write-in-effect");

    let i = 0;
    const typeInterval = setInterval(() => {
      if (i < text.length) {
        this.element.textContent += text.charAt(i);
        i++;
      } else {
        clearInterval(typeInterval);
        // Remove the blinking cursor after typing is complete
        setTimeout(() => {
          this.element.classList.remove("write-in-effect");
        }, 1000);
      }
    }, speed);
  }
}
```

### Step 19: Update Views to Use Custom Components

Update the todo display in `app/views/projects/show.html.erb` to use the new components:

```erb
<!-- Replace the existing todos section with: -->
<% if @todos.any? %>
  <div class="space-y-3">
    <% @todos.each do |todo| %>
      <div class="todo-item flex items-start space-x-3 p-4 bg-white border-2 border-gray-200 rounded-lg hover:border-gray-300 transition-all duration-200 hand-drawn-border"
           data-controller="todo"
           data-todo-project-id-value="<%= @project.id %>"
           data-todo-todo-id-value="<%= todo.id %>"
           data-todo-completed-value="<%= todo.completed %>">

        <!-- Custom Checkbox -->
        <div class="flex-shrink-0 mt-1">
          <%= render 'shared/custom_checkbox',
              name: "todo[completed]",
              value: "1",
              checked: todo.completed,
              onchange_js: "todo#toggle",
              todo_id: todo.id %>
        </div>

        <!-- Todo Content -->
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between">
            <h4 class="text-lg font-handwriting text-gray-900 transition-all duration-300 <%= 'line-through text-gray-500' if todo.completed %>"
                data-todo-target="title">
              <%= todo.title %>
            </h4>

            <div class="flex items-center space-x-2 opacity-0 group-hover:opacity-100 transition-opacity">
              <%= link_to "✏️", edit_project_todo_path(@project, todo),
                  class: "text-blue-600 hover:text-blue-800 text-sm hover:scale-110 transition-transform" %>
              <%= link_to "🗑️", project_todo_path(@project, todo),
                  method: :delete,
                  confirm: "Are you sure?",
                  class: "text-red-600 hover:text-red-800 text-sm hover:scale-110 transition-transform" %>
            </div>
          </div>

          <% if todo.notes.present? %>
            <p class="mt-2 text-sm text-gray-600 font-casual transition-all duration-300 <%= 'line-through text-gray-400' if todo.completed %>"
               data-todo-target="notes">
              <%= todo.notes %>
            </p>
          <% end %>

          <div class="mt-2 flex items-center space-x-4 text-xs text-gray-400">
            <span>Position: <%= todo.position %></span>
            <span>Created: <%= todo.created_at.strftime("%b %d") %></span>
          </div>
        </div>
      </div>
    <% end %>
  </div>
<% else %>
  <!-- Enhanced empty state -->
  <div class="text-center py-12">
    <div class="animate-bounce-in">
      <div class="text-6xl mb-4">📝</div>
      <h3 class="text-xl font-handwriting text-gray-900 mb-2">No todos yet!</h3>
      <p class="text-gray-600 font-casual">Add your first todo above to get started on this project.</p>
    </div>
  </div>
<% end %>
```

**Learning Explanation - Advanced Rails/JavaScript Integration:**

1. **Stimulus Data API**: `data-controller`, `data-target`, and `data-value` attributes connect HTML to JavaScript
2. **AJAX Forms**: Submitting forms without page refresh using `fetch()` API
3. **CSS Animations**: Combining Tailwind utility classes with custom keyframe animations
4. **Progressive Enhancement**: The app works without JavaScript, but is enhanced with it

---

## Phase 6: Testing and Quality Assurance (Days 8-9)

### Step 20: Set Up Testing Framework

```bash
# Add testing gems to Gemfile (in test group)
bundle add rspec-rails capybara selenium-webdriver --group=test

# Generate RSpec configuration
bin/rails generate rspec:install

# Generate system test configuration
bin/rails generate system_test_config
```

### Step 21: Write Model Tests

Create `spec/models/user_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires an email address' do
      user = User.new(password: 'password123')
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it 'requires a unique email address' do
      User.create!(email_address: 'test@example.com', password: 'password123')
      duplicate_user = User.new(email_address: 'test@example.com', password: 'password123')

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email_address]).to include('has already been taken')
    end

    it 'requires a valid email format' do
      user = User.new(email_address: 'invalid-email', password: 'password123')
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include('is invalid')
    end
  end

  describe 'associations' do
    it 'has many projects' do
      user = User.create!(email_address: 'test@example.com', password: 'password123')
      project1 = user.projects.create!(name: 'Project 1')
      project2 = user.projects.create!(name: 'Project 2')

      expect(user.projects).to include(project1, project2)
    end

    it 'destroys associated projects when user is deleted' do
      user = User.create!(email_address: 'test@example.com', password: 'password123')
      project = user.projects.create!(name: 'Test Project')

      expect { user.destroy }.to change { Project.count }.by(-1)
    end
  end
end
```

Create `spec/models/project_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Project, type: :model do
  let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

  describe 'validations' do
    it 'requires a name' do
      project = user.projects.build(name: '')
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end

    it 'requires a user' do
      project = Project.new(name: 'Test Project')
      expect(project).not_to be_valid
      expect(project.errors[:user]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      project = user.projects.create!(name: 'Test Project')
      expect(project.user).to eq(user)
    end

    it 'has many todos' do
      project = user.projects.create!(name: 'Test Project')
      todo1 = project.todos.create!(title: 'Todo 1')
      todo2 = project.todos.create!(title: 'Todo 2')

      expect(project.todos).to include(todo1, todo2)
    end
  end

  describe 'methods' do
    let(:project) { user.projects.create!(name: 'Test Project') }

    it 'calculates completion percentage correctly' do
      project.todos.create!(title: 'Todo 1', completed: true)
      project.todos.create!(title: 'Todo 2', completed: false)
      project.todos.create!(title: 'Todo 3', completed: true)

      expect(project.completion_percentage).to eq(67) # 2/3 * 100, rounded
    end

    it 'returns 0% for projects with no todos' do
      expect(project.completion_percentage).to eq(0)
    end
  end
end
```

### Step 22: Write System Tests

Create `spec/system/authentication_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Authentication', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'User registration' do
    it 'allows a user to sign up with valid information' do
      visit sign_up_path

      fill_in 'Email address', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      click_button 'Create Account'

      expect(page).to have_content('Welcome! Your account was created successfully.')
      expect(page).to have_content('My Projects')
    end

    it 'shows errors for invalid registration' do
      visit sign_up_path

      fill_in 'Email address', with: 'invalid-email'
      fill_in 'Password', with: 'short'
      click_button 'Create Account'

      expect(page).to have_content('There was a problem creating your account')
    end
  end

  describe 'User sign in' do
    let!(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

    it 'allows a user to sign in with valid credentials' do
      visit new_session_path

      fill_in 'Email address', with: 'test@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign In'

      expect(page).to have_content('My Projects')
    end

    it 'rejects invalid credentials' do
      visit new_session_path

      fill_in 'Email address', with: 'test@example.com'
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Sign In'

      expect(page).to have_content('Sign In') # Still on sign in page
    end
  end
end
```

Create `spec/system/todo_management_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Todo Management', type: :system do
  let!(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }
  let!(:project) { user.projects.create!(name: 'Test Project') }

  before do
    driven_by(:rack_test)

    # Sign in the user
    visit new_session_path
    fill_in 'Email address', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    click_button 'Sign In'
  end

  describe 'Creating todos' do
    it 'allows creating a new todo' do
      visit project_path(project)

      fill_in 'What needs to be done?', with: 'Learn RSpec testing'
      fill_in 'Additional notes (optional)', with: 'Focus on system tests'
      click_button 'Add Todo'

      expect(page).to have_content('Learn RSpec testing')
      expect(page).to have_content('Focus on system tests')
      expect(page).to have_content('Todo was successfully created.')
    end

    it 'shows validation errors for empty todos' do
      visit project_path(project)

      fill_in 'What needs to be done?', with: ''
      click_button 'Add Todo'

      expect(page).to have_content("Title can't be blank")
    end
  end

  describe 'Managing todos' do
    let!(:todo) { project.todos.create!(title: 'Test todo', notes: 'Test notes') }

    it 'allows marking todos as complete' do
      visit project_path(project)

      check 'todo[completed]'

      # The form should submit automatically via JavaScript
      # In a real browser test, we'd see the visual changes
      expect(todo.reload).to be_completed
    end

    it 'allows editing todos' do
      visit project_path(project)

      click_link 'Edit'
      fill_in 'Title', with: 'Updated todo title'
      click_button 'Update Todo'

      expect(page).to have_content('Updated todo title')
      expect(page).to have_content('Todo was successfully updated.')
    end

    it 'allows deleting todos' do
      visit project_path(project)

      accept_confirm do
        click_link 'Delete'
      end

      expect(page).not_to have_content('Test todo')
      expect(page).to have_content('Todo was successfully deleted.')
    end
  end
end
```

### Step 23: Run Tests and Fix Issues

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/system/authentication_spec.rb

# Run tests with coverage (add simplecov gem first)
bundle add simplecov --group=test
bundle exec rspec --format documentation
```

**Learning Note:** Testing is crucial for maintaining code quality as your application grows. System tests verify the entire user experience, while unit tests ensure individual components work correctly.

---

## Phase 7: Deployment and Production Setup (Days 9-10)

### Step 24: Prepare for Production

Add production gems to `Gemfile`:

```ruby
group :production do
  gem 'pg' # PostgreSQL for production
  gem 'redis' # For caching and background jobs
end
```

Update `config/database.yml` for production:

```yaml
production:
  <<: *default
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
```

Create `config/environments/production.rb` optimizations:

```ruby
Rails.application.configure do
  # Existing configuration...

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = ENV['ASSET_HOST'] if ENV['ASSET_HOST'].present?

  # Compress CSS using a preprocessor.
  config.assets.css_compressor = :sass

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.variant_processor = :mini_magick
end
```

### Step 25: Deploy to Digital Ocean with Docker

Rails 8.0.2 comes with Docker support built-in. We'll deploy to a Digital Ocean droplet.

First, let's verify the Docker setup:

```bash
# Rails 8.0.2 includes a Dockerfile by default
cat Dockerfile

# Build the Docker image locally to test
docker build -t todo-app .

# Test the container locally
docker run -p 3000:3000 -e RAILS_MASTER_KEY=$(cat config/master.key) todo-app
```

**Set up Digital Ocean Droplet:**

1. Create a Digital Ocean account and droplet:

   - Choose Ubuntu 22.04 LTS
   - Select at least 2GB RAM / 1 CPU
   - Enable monitoring and backups

2. Install Docker on the droplet:

```bash
# SSH into your droplet
ssh root@your-droplet-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose-plugin

# Create app directory
mkdir -p /var/www/todo-app
cd /var/www/todo-app
```

3. Create production docker-compose.yml:

```yaml
# docker-compose.production.yml
version: "3.8"
services:
  app:
    build: .
    ports:
      - "80:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://todo_user:your_password@db:5432/todo_production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
    depends_on:
      - db
    volumes:
      - storage_data:/rails/storage
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=todo_production
      - POSTGRES_USER=todo_user
      - POSTGRES_PASSWORD=your_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  storage_data:
```

4. Deploy the application:

```bash
# Copy your app files to the droplet
scp -r . root@your-droplet-ip:/var/www/todo-app/

# SSH into droplet and start services
ssh root@your-droplet-ip
cd /var/www/todo-app

# Set environment variables
export RAILS_MASTER_KEY=your_master_key_here

# Build and start services
docker compose -f docker-compose.production.yml up -d --build

# Run database migrations
docker compose -f docker-compose.production.yml exec app bin/rails db:create db:migrate
```

### Step 26: Set Up Custom Domain and SSL

1. **Configure Nginx with SSL:**

Create `/var/www/todo-app/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:3000;
    }

    server {
        listen 80;
        server_name todos.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name todos.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

2. **Set up SSL certificates using Let's Encrypt:**

```bash
# Install certbot
apt install certbot

# Get SSL certificate
certbot certonly --standalone -d todos.yourdomain.com

# Copy certificates to nginx directory
mkdir -p /var/www/todo-app/ssl
cp /etc/letsencrypt/live/todos.yourdomain.com/fullchain.pem /var/www/todo-app/ssl/cert.pem
cp /etc/letsencrypt/live/todos.yourdomain.com/privkey.pem /var/www/todo-app/ssl/key.pem
```

3. **Update DNS records:**
   - Add an A record pointing `todos.yourdomain.com` to your droplet's IP address

### Step 27: Post-Deployment Tasks

```bash
# Check application status
docker compose -f docker-compose.production.yml ps

# View application logs
docker compose -f docker-compose.production.yml logs -f app

# Access Rails console in production
docker compose -f docker-compose.production.yml exec app bin/rails console

# Run database migrations (if needed)
docker compose -f docker-compose.production.yml exec app bin/rails db:migrate

# Restart services
docker compose -f docker-compose.production.yml restart

# Update SSL certificates (set up auto-renewal)
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet && docker compose -f /var/www/todo-app/docker-compose.production.yml restart nginx
```

**Learning Note:** Production deployment involves many considerations:

- Database differences (SQLite vs PostgreSQL)
- Environment variables for sensitive data
- Asset compilation and serving
- SSL certificates and domain configuration
- Monitoring and logging

---

## Troubleshooting Guide

### Common Issues and Solutions

**Issue: Tailwind styles not loading**

```bash
# Rebuild Tailwind
bin/rails tailwindcss:build

# Check if Tailwind process is running
bin/rails tailwindcss:watch
```

**Issue: Authentication not working**

```bash
# Check if sessions table exists
bin/rails console
Session.count

# Verify User model has has_secure_password
User.new.respond_to?(:authenticate)
```

**Issue: Database relationship errors**

```bash
# Check foreign keys
bin/rails console
Project.first.user
Todo.first.project
```

**Issue: JavaScript not working**

```bash
# Check Stimulus controllers are loaded
# Open browser dev tools, look for JavaScript errors
# Verify data-controller attributes match controller names
```

**Issue: Deployment failures**

```bash
# Check container logs
docker compose -f docker-compose.production.yml logs app

# Check all services status
docker compose -f docker-compose.production.yml ps

# Check database connection
docker compose -f docker-compose.production.yml exec app bin/rails db:migrate:status

# Rebuild containers if needed
docker compose -f docker-compose.production.yml up -d --build
```

---

## Final Learning Summary

Congratulations! You've built a complete Rails application with modern authentication, beautiful UI, and production deployment. Here's what you've learned:

### Core Rails Concepts Mastered

- **MVC Architecture**: Clean separation of concerns
- **Active Record**: Database relationships and queries
- **Routing**: RESTful routes and nested resources
- **Authentication**: Rails 8.2 built-in auth system
- **Asset Pipeline**: Tailwind CSS integration
- **Testing**: Model and system tests with RSpec

### Advanced Techniques Applied

- **Custom Stimulus Controllers**: Interactive JavaScript behavior
- **CSS Animations**: Hand-drawn aesthetic with smooth transitions
- **Form Handling**: AJAX submissions and validation
- **Database Design**: Proper relationships and constraints
- **Deployment**: Production-ready configuration

### Best Practices Implemented

- **Security**: CSRF protection, password hashing, data scoping
- **Performance**: Database query optimization, asset compilation
- **User Experience**: Progressive enhancement, responsive design
- **Code Quality**: Testing, validation, error handling

### Next Steps for Continued Learning

1. **Add more features**: File uploads, email notifications, team collaboration
2. **Improve performance**: Caching, background jobs, database optimization
3. **Enhance testing**: More comprehensive test coverage, performance testing
4. **Learn advanced Rails**: Action Cable (WebSockets), API development, microservices

You now have a solid foundation in modern Rails development and can confidently build and deploy web applications!

---

## Additional Resources

- **Rails Guides**: https://guides.rubyonrails.org/
- **Rails API Docs**: https://api.rubyonrails.org/
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Stimulus Handbook**: https://stimulus.hotwired.dev/handbook/introduction
- **RSpec Documentation**: https://rspec.info/documentation/
- **Docker with Rails**: https://docs.docker.com/samples/rails/
- **Digital Ocean Droplet Setup**: https://www.digitalocean.com/community/tutorials
