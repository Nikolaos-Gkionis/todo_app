class ProjectsController < ApplicationController
  # Require authentication for all actions
  before_action :require_login

  def index
    # Only show current user's projects
    @projects = current_user.projects
  end

  def show
    # Only allow access to current user's projects
    @project = current_user.projects.find(params[:id])
    @todos = @project.todos
    @new_todo = @project.todos.build
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

  private

  def project_params
    params.require(:project).permit(:name, :description, :cover_color)
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
