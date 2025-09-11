class TodosController < ApplicationController
  before_action :set_project
  before_action :set_todo, only: [:edit, :update, :destroy]

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
      @todos = @project.todos
      @new_todo = @todo
      render 'projects/show'
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      redirect_to @project, notice: 'Todo was successfully updated.'
    else
      @todos = @project.todos
      @new_todo = @project.todos.build
      render 'projects/show'
    end
  end

  def destroy
    @todo.destroy
    redirect_to @project, notice: 'Todo was successfully deleted.'
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_todo
    @todo = @project.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :notes, :completed, :position)
  end
end