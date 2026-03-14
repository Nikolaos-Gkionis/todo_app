class PagesController < ApplicationController
  # Require authentication for all actions except offline
  before_action :require_login, except: [ :offline ]
  before_action :set_page, only: [ :show, :edit, :update, :destroy ]

  def index
    redirect_to app_root_path
  end

  def reorder
    page_ids = params[:page_ids]
    if page_ids.present?
      page_ids.each_with_index do |id, index|
        current_user.pages.where(id: id).update_all(position: index + 1)
      end
      render json: { success: true }
    else
      render json: { success: false }, status: :bad_request
    end
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
    # Check if user can create more pages (development: skip limit for testing)
    unless Rails.env.development? || current_user.can_create_page?
      msg = if current_user.trial_expired? && !current_user.device_downloaded?
        "Your trial has expired. Please download the app to continue creating pages."
      else
        "You've reached the page limit. Download the app for unlimited pages!"
      end
      respond_to do |format|
        format.html { redirect_to "#{app_root_path}?panel=open", alert: msg }
        format.json { render json: { error: "limit", message: msg }, status: :forbidden }
      end
      return
    end

    # Create page for current user
    @page = current_user.pages.build(page_params)

    if @page.save
      redirect_url = "#{app_root_path}?panel=open"
      respond_to do |format|
        format.html { redirect_to redirect_url, notice: "Page was successfully created." }
        format.json { render json: { success: true, redirect: redirect_url } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: "validation", errors: @page.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    # @page is set by before_action
    # Just render the edit form
  end

  def update
    # @page is set by before_action
    if @page.update(page_params)
      respond_to do |format|
        format.html { redirect_to @page, notice: "Page was successfully updated." }
        format.json { render json: { status: "success", name: @page.name } }
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Please fix the errors below."
          render :edit, status: :unprocessable_entity
        end
        format.json { render json: { status: "error", errors: @page.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # @page is set by before_action
    @page.destroy
    redirect_to app_root_path, notice: "Page was successfully deleted."
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
