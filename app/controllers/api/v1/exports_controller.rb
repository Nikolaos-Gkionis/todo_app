# frozen_string_literal: true

module Api
  module V1
    # One-shot snapshot for the Omarchy helper.
    # Paid sign-in copies this onto the machine, then daily work stays local —
    # so peponi.to does not have to keep hosting the todo list.
    class ExportsController < BaseController
      # GET /api/v1/export
      def show
        render json: {
          days: dated_focus_days,
          not_yet: not_yet_rows,
          user: {
            email: current_user.email_address,
            name: current_user.display_name,
            app_title: current_user.app_title,
            not_yet_panel_title: current_user.not_yet_panel_title
          }
        }
      end

      private

      # Focus column: dated todos that are not on a list page.
      def dated_focus_days
        days = {}
        current_user.todos
          .where(page_id: nil)
          .where.not(due_date: nil)
          .order(:due_date, :position, :id)
          .each do |todo|
            key = todo.due_date.iso8601
            (days[key] ||= []) << serialize_todo(todo)
          end
        days
      end

      # Not Yet drawer: undated list todos, flattened for the local store.
      def not_yet_rows
        rows = []
        current_user.pages.includes(:todos).order(:position, :created_at).each do |page|
          page.todos.order(:position, :id).each do |todo|
            next if todo.is_visual_break?

            rows << serialize_todo(todo).merge("list" => page.name.to_s)
          end
        end
        rows
      end
    end
  end
end
