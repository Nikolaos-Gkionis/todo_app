class TodosController < ApplicationController
  # Require authentication for all actions
  before_action :require_login
  before_action :set_project
  before_action :set_todo, only: [:edit, :update, :destroy]

  def index
    redirect_to @project
  end

  def new
    @todo = @project.todos.build
  end

  def create
    Rails.logger.info "=== TODO CREATE DEBUG ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "todo_params: #{todo_params.inspect}"
    
    @todo = @project.todos.build(todo_params)
    Rails.logger.info "Todo built: #{@todo.inspect}"
    Rails.logger.info "Todo valid?: #{@todo.valid?}"
    Rails.logger.info "Todo errors: #{@todo.errors.full_messages}" unless @todo.valid?
    
    if @todo.save
      # Add animation flag for the new todo
      flash[:new_todo_id] = @todo.id
      redirect_to @project, notice: '✨ Todo added!'
    else
      Rails.logger.error "Todo save failed: #{@todo.errors.full_messages}"
      # Only get saved todos to avoid routing errors
      @todos = @project.todos.ordered.where.not(id: nil)
      @new_todo = @todo
      render 'projects/show', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      redirect_to @project, notice: 'Todo was successfully updated.'
    else
      # Only get saved todos to avoid routing errors  
      @todos = @project.todos.ordered.where.not(id: nil)
      @new_todo = @project.todos.build
      render 'projects/show', status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    redirect_to @project, notice: 'Todo was successfully deleted.'
  end

  # AJAX endpoint for reordering todos
  def reorder
    Rails.logger.info "=== REORDER DEBUG ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "todo_ids: #{params[:todo_ids].inspect}"
    
    todo_ids = params[:todo_ids]
    
    if todo_ids.present?
      Rails.logger.info "Reordering todos: #{todo_ids}"
      Todo.reorder_positions!(@project, todo_ids)
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

  def set_project
    # Only allow access to current user's projects
    @project = current_user.projects.find(params[:project_id])
  end

  def set_todo
    @todo = @project.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position)
  end
end