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
