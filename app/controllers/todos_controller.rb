class TodosController < ApplicationController
  def index
  end

  def new
  end

  def create
    @project = Project.find(params[:project_id])
    @todo = @project.todos.build(todo_params)
    
    if @todo.save
      redirect_to @project, notice: 'Todo was successfully created.'
    else
      @todos = @project.todos
      @new_todo = @todo  # Keep the failed todo to show errors
      render 'projects/show'
    end
  end
  
  private
  
  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position)
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
