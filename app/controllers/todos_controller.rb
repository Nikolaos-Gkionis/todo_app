class TodosController < ApplicationController
  # Require authentication for all actions
  before_action :require_login
  before_action :set_page
  before_action :set_todo, only: [:edit, :update, :destroy]

  def index
    redirect_to @page
  end

  def new
    @todo = @page.todos.build
  end

  def create
    Rails.logger.info "=== TODO CREATE DEBUG ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "todo_params: #{todo_params.inspect}"
    
    # Check if user can add more todos to this page
    unless @page.can_add_todo?
      redirect_to @page, alert: "Free users can only add #{User::MAX_FREE_TODOS_PER_PAGE} todos per page. Upgrade to Premium for unlimited todos!"
      return
    end
    
    @todo = @page.todos.build(todo_params)
    Rails.logger.info "Todo built: #{@todo.inspect}"
    Rails.logger.info "Todo valid?: #{@todo.valid?}"
    Rails.logger.info "Todo errors: #{@todo.errors.full_messages}" unless @todo.valid?
    
    if @todo.save
      # Add animation flag for the new todo
      flash[:new_todo_id] = @todo.id
      redirect_to @page, notice: '✨ Todo added to Todo-it!'
    else
      Rails.logger.error "Todo save failed: #{@todo.errors.full_messages}"
      # Only get saved todos to avoid routing errors
      @todos = @page.todos.ordered.where.not(id: nil)
      @new_todo = @todo
      render 'pages/show', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      redirect_to @page, notice: 'Todo was successfully updated.'
    else
      # Only get saved todos to avoid routing errors  
      @todos = @page.todos.ordered.where.not(id: nil)
      @new_todo = @page.todos.build
      render 'pages/show', status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    redirect_to @page, notice: 'Todo was successfully deleted.'
  end

  # AJAX endpoint for reordering todos
  def reorder
    Rails.logger.info "=== REORDER DEBUG ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "todo_ids: #{params[:todo_ids].inspect}"
    
    todo_ids = params[:todo_ids]
    
    if todo_ids.present?
      Rails.logger.info "Reordering todos: #{todo_ids}"
      Todo.reorder_positions!(@page, todo_ids)
      Rails.logger.info "Reorder completed successfully"
      render json: { success: true, message: "Todos reordered successfully" }
    else
      Rails.logger.error "No todo IDs provided in reorder request"
      render json: { success: false, error: 'No todo IDs provided' }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Error in reorder: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  private

  def set_page
    # Only allow access to current user's pages
    @page = current_user.pages.find(params[:page_id])
  end

  def set_todo
    @todo = @page.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position, :due_date)
  end
end