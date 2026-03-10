class DashboardController < ApplicationController
  before_action :require_login

  def index
    today = Time.current.to_date

    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : today

    # View switcher: default 7 days (full week), persisted in session
    days = (params[:days] || session[:dashboard_days] || 7).to_i
    days = 7 unless [ 1, 2, 4, 7 ].include?(days)
    session[:dashboard_days] = days
    @view_days = days

    # Calculate date range based on selected view
    @week_dates = (@start_date...(@start_date + days.days)).to_a

    # Process week todos
    @week_todos = current_user.todos.where(due_date: @week_dates)
    @todos_by_date = @week_todos.group_by(&:due_date)

    # Process custom lists
    @pages = current_user.pages.includes(:todos).order(created_at: :desc)
  end
end
