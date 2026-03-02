class PagesController < ApplicationController
  # Require authentication for all actions except offline
  before_action :require_login, except: [ :offline ]
  before_action :set_page, only: [ :show, :edit, :update, :destroy ]

  def index
    # Only show current user's pages, ordered by newest first
    @pages = current_user.pages.order(created_at: :desc)
  end

  def show
    # @page is set by before_action
    @todos = @page.todos.ordered.where.not(id: nil)  # Get saved todos in position order
    @new_todo = @page.todos.build                    # New todo for the form

    # Calendar template: prepare week dates and grouped todos
    if @page.template == "calendar"
      today = Time.current.to_date
      @week_start = today.beginning_of_week(:monday)
      @week_end = @week_start + 6.days
      @week_dates = (@week_start..@week_end).to_a
      # Todos with due_date in this week, grouped by date
      @todos_by_date = @todos.select { |t| t.due_date.present? }.group_by(&:due_date)
      @unscheduled_todos = @todos.reject(&:due_date)
      # Index of today for mobile scroll (0=Monday)
      @today_index = @week_dates.index(today) || 0
    end
  end

  def new
    # Create new page for current user (template defaults to minimal)
    @page = current_user.pages.build(template: "minimal")
  end

  def create
    # Check if user can create more pages
    unless current_user.can_create_page?
      if current_user.trial_expired? && !current_user.device_downloaded?
        redirect_to pages_path, alert: "Your trial has expired. Please download the app to continue creating pages."
      else
        redirect_to pages_path, alert: "You've reached the page limit. Download the app for unlimited pages!"
      end
      return
    end

    # Create page for current user
    @page = current_user.pages.build(page_params)

    if @page.save
      redirect_to pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @page is set by before_action
    # Just render the edit form
  end

  def update
    # @page is set by before_action
    if @page.update(page_params)
      redirect_to @page, notice: "Page was successfully updated."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # @page is set by before_action
    @page.destroy
    redirect_to pages_path, notice: "Page was successfully deleted."
  end

  # Offline page for service worker
  def offline
    render layout: false
  end

  private

  def set_page
    # Only allow access to current user's pages
    @page = current_user.pages.find(params[:id])
  end

  def page_params
    params.require(:page).permit(:name, :description, :cover_color, :template)
  end
end
