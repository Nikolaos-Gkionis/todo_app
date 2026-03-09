class TodosController < ApplicationController
  before_action :require_login
  before_action :set_todo, only: [ :update, :destroy ]

  def create
    @todo = current_user.todos.build(todo_params)

    if @todo.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: app_root_path, notice: "Todo added!" }
      end
    else
      # If validation fails, we should ideally handle it, but for inline forms, redirecting back works best
      redirect_back fallback_location: app_root_path, alert: "Failed to create todo."
    end
  end

  def update
    # Support reassignment via assign_to_page or assign_to_date
    if params[:todo][:page_id] == "null"
      @todo.assign_to_date(params[:todo][:due_date])
    elsif params[:todo][:page_id].present?
      @todo.assign_to_page(params[:todo][:page_id])
    end

    old_rule = @todo.recurrence_rule

    if @todo.update(todo_params.except(:page_id, :due_date))
      if @todo.due_date.present? && @todo.recurrence_rule.present? && @todo.recurrence_rule != old_rule
        replicate_recurring_todos(@todo)
      end
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: app_root_path, notice: "Todo updated." }
        format.json { render json: { status: "success", id: @todo.id } }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: app_root_path, alert: "Failed to update todo." }
        format.json { render json: { status: "error", errors: @todo.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @todo.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: app_root_path, notice: "Todo deleted." }
    end
  end

  def reorder
    todo_ids = params[:todo_ids]

    if todo_ids.present?
      # Ensure all todos belong to user
      valid_todos = current_user.todos.where(id: todo_ids).pluck(:id).map(&:to_s)

      # Filter incoming order to only what the user owns
      safe_todo_ids = todo_ids.select { |id| valid_todos.include?(id.to_s) }
      Todo.reorder_positions!(safe_todo_ids)

      render json: { success: true }
    else
      render json: { success: false, error: "No todo IDs provided" }, status: :bad_request
    end
  rescue => e
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  private

  def set_todo
    @todo = current_user.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position, :due_date, :page_id, :bold, :highlight_color, :recurrence_rule, :is_visual_break)
  end

  def replicate_recurring_todos(source_todo)
    rule = source_todo.recurrence_rule
    current_date = source_todo.due_date
    end_date = current_date + 30.days

    # Generate dates based on the rule
    dates_to_create = []
    current = current_date + 1.day

    while current <= end_date
      case rule
      when "every day"
        dates_to_create << current
        current += 1.day
      when "every weekday"
        dates_to_create << current if (1..5).cover?(current.wday)
        current += 1.day
      when "every week"
        current = current_date + dates_to_create.size.weeks + 1.week
        dates_to_create << current if current <= end_date
      when "every month"
        current = current_date + dates_to_create.size.months + 1.month
        dates_to_create << current if current <= end_date
      when "every year"
        current = current_date + dates_to_create.size.years + 1.year
        dates_to_create << current if current <= end_date
      else
        break
      end
    end

    # Bulk insert for efficiency
    todos_to_insert = dates_to_create.map do |date|
      {
        user_id: source_todo.user_id,
        title: source_todo.title,
        notes: source_todo.notes,
        due_date: date,
        page_id: source_todo.page_id,
        bold: source_todo.bold,
        highlight_color: source_todo.highlight_color,
        recurrence_rule: source_todo.recurrence_rule,
        completed: false,
        position: source_todo.position,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    if todos_to_insert.any?
      Todo.insert_all(todos_to_insert)

      # Also update the original todo to not overwrite later checks
      source_todo.update_column(:recurrence_rule, rule)
    end
  end
end
