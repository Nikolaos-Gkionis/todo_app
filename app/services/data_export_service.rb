# frozen_string_literal: true

# Service for exporting and importing user data for the trial-to-download transition
class DataExportService
  EXPORT_VERSION = "1.0"

  def self.export_user_data(user)
    new(user).export_data
  end

  def self.import_user_data(user, json_data)
    new(user).import_data(json_data)
  end

  def initialize(user)
    @user = user
  end

  def export_data
    {
      metadata: export_metadata,
      user: export_user_data,
      pages: export_pages_data,
      export_timestamp: Time.current.iso8601
    }.to_json
  end

  def import_data(json_data)
    data = JSON.parse(json_data)
    validate_import_data(data)

    # Import in correct order: pages first, then todos
    import_pages(data["pages"])

    # Mark data as imported and user as having downloaded
    @user.update!(trial_data_exported: true, device_downloaded: true)
  end

  private

  def export_metadata
    {
      version: EXPORT_VERSION,
      exported_at: Time.current.iso8601,
      app_name: "Todo-it",
      trial_user_id: @user.id,
      total_pages: @user.pages.count,
      total_todos: @user.pages.joins(:todos).count
    }
  end

  def export_user_data
    # Export non-sensitive user information
    {
      id: @user.id,
      name: @user.name,
      email_domain: @user.email_address.split("@").last, # Only domain for privacy
      trial_started_at: @user.trial_started_at&.iso8601,
      trial_expires_at: @user.trial_expires_at&.iso8601,
      created_at: @user.created_at.iso8601
    }
  end

  def export_pages_data
    @user.pages.includes(:todos).map do |page|
      {
        id: page.id,
        name: page.name,
        description: page.description,
        cover_color: page.cover_color,
        created_at: page.created_at.iso8601,
        updated_at: page.updated_at.iso8601,
        todos: export_page_todos(page.todos)
      }
    end
  end

  def export_page_todos(todos)
    todos.ordered.map do |todo|
      {
        id: todo.id,
        title: todo.title,
        notes: todo.notes,
        completed: todo.completed,
        position: todo.position,
        due_date: todo.due_date&.iso8601,
        created_at: todo.created_at.iso8601,
        updated_at: todo.updated_at.iso8601
      }
    end
  end

  def validate_import_data(data)
    raise ArgumentError, "Invalid export data: missing metadata" unless data["metadata"]
    raise ArgumentError, "Invalid export version" unless data["metadata"]["version"] == EXPORT_VERSION
    raise ArgumentError, "Invalid export data: missing pages" unless data["pages"].is_a?(Array)
  end

  def import_pages(pages_data)
    pages_data.each do |page_data|
      # Create page with original ID if possible, or generate new one
      page = @user.pages.create!(
        name: page_data["name"],
        description: page_data["description"] || "",
        cover_color: page_data["cover_color"]
      )

      # Import todos for this page
      import_page_todos(page, page_data["todos"]) if page_data["todos"]
    end
  end

  def import_page_todos(page, todos_data)
    todos_data.each do |todo_data|
      page.todos.create!(
        title: todo_data["title"],
        notes: todo_data["notes"] || "",
        completed: todo_data["completed"] || false,
        position: todo_data["position"] || 1,
        due_date: todo_data["due_date"] ? Date.parse(todo_data["due_date"]) : nil
      )
    end
  end
end
