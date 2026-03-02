class DashboardController < ApplicationController
  before_action :require_login

  def index
    # Week calculation
    today = Time.current.to_date
    @week_start = today.beginning_of_week(:monday)
    @week_end = @week_start + 6.days
    @week_dates = (@week_start..@week_end).to_a

    # Process week todos
    @week_todos = current_user.todos.where(due_date: @week_dates)
    @todos_by_date = @week_todos.group_by(&:due_date)

    # Process custom lists
    @pages = current_user.pages.includes(:todos).order(created_at: :desc)
  end
end
