# frozen_string_literal: true

module Api
  module V1
    class NotYetController < BaseController
      # GET /api/v1/not_yet — pages (lists) and their undated list todos
      def show
        pages = current_user.pages.includes(:todos).order(:position, :created_at)

        render json: {
          title: current_user.not_yet_panel_title.presence || "Not Yet",
          pages: pages.map { |page|
            {
              id: page.id,
              name: page.name.to_s,
              todos: page.todos.order(:position, :id).map { |t| serialize_todo(t) }
            }
          }
        }
      end
    end
  end
end
