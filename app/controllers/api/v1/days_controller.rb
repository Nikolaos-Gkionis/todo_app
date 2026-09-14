# frozen_string_literal: true

module Api
  module V1
    class DaysController < BaseController
      # GET /api/v1/days/:date  (YYYY-MM-DD)
      def show
        date = parse_date!(params[:date])
        return if performed?

        todos = current_user.todos
          .where(due_date: date, page_id: nil)
          .order(:position, :id)

        render json: {
          date: date.iso8601,
          tasks: todos.map { |t| serialize_todo(t) }
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
