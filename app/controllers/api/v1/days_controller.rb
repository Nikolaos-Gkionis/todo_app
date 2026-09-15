# frozen_string_literal: true

module Api
  module V1
    class DaysController < BaseController
      # GET /api/v1/days/:date  (YYYY-MM-DD)
      def show
        date = parse_date!(params[:date])
        return if performed?

        # Same as the website dashboard: if the user rolls unfinished
        # tasks forward, leftover open todos land on today.
        if current_user.roll_over? && date == Date.current
          current_user.todos.pending.where("due_date < ?", date).update_all(due_date: date)
        end

        todos = current_user.todos
          .where(due_date: date, page_id: nil)
          .order(:position, :id)

        render json: {
          date: date.iso8601,
          tasks: todos.map { |t| serialize_todo(t) },
          prefs: { roll_over: current_user.roll_over != false }
        }
      end

      # POST /api/v1/days/:date/tasks
      # Body: { title }
      # Creates a Focus-column task (due_date set, page_id nil) like the website.
      def create_task
        date = parse_date!(params[:date])
        return if performed?

        title = params[:title].presence ||
          params.dig(:task, :title).presence ||
          params.dig(:day, :title)
        todo = current_user.todos.new(
          title: title.to_s.strip,
          due_date: date,
          page_id: nil
        )

        if todo.save
          render json: { task: serialize_todo(todo) }, status: :created
        else
          render json: {
            error: "validation_failed",
            message: todo.errors.full_messages.to_sentence.presence || "Could not save task."
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/days/:date/reorder
      # Body: { todo_ids: [1, 2, 3] } — new order for that day's Focus list.
      def reorder
        date = parse_date!(params[:date])
        return if performed?

        ids = Array(params[:todo_ids]).map { |id| Integer(id) rescue nil }.compact
        scoped = current_user.todos.where(due_date: date, page_id: nil, id: ids)
        if ids.empty? || scoped.count != ids.size
          render json: { error: "not_found", message: "Those tasks are not on this day." }, status: :not_found
          return
        end

        Todo.reorder_positions!(ids)
        render json: { ok: true, todo_ids: ids }
      end

      private

      def parse_date!(value)
        Date.iso8601(value.to_s)
      rescue ArgumentError, TypeError
        render json: { error: "invalid_date", message: "Use YYYY-MM-DD." }, status: :unprocessable_entity
        nil
      end
    end
  end
end
