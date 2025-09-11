class ProjectsController < ApplicationController
  # Require authentication for all actions
  before_action :require_login
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    # Only show current user's projects
    @projects = current_user.projects
  end

  def show
    # @project is set by before_action
    @todos = @project.todos.ordered.where.not(id: nil)  # Get saved todos in order
    @new_todo = @project.todos.build                    # New todo for the form
  end

  def new
    # Create new project for current user
    @project = current_user.projects.build
  end

  def create
    # Create project for current user
    @project = current_user.projects.build(project_params)
  
    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @project is set by before_action
    # Just render the edit form
  end

  def update
    # @project is set by before_action
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      flash.now[:alert] = 'Please fix the errors below.'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # @project is set by before_action
    @project.destroy
    redirect_to projects_path, notice: 'Project was successfully deleted.'
  end

  private

  def set_project
    # Only allow access to current user's projects
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :cover_color)
  end
end
