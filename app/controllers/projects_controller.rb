class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
    @todos = @project.todos
    @new_todo = @project.todos.build
  end

  def new
    @project = Project.new
    @project.user = User.first  # Temporary: assign to first user
  end

  def create
    @project = Project.new(project_params)
    @project.user = User.first  # Temporary: assign to first user
  
    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      render :new
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
