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

      # POST /api/v1/not_yet/tasks
      # Body: { title }
      # Undated list task, same as the website Not Yet inbox.
      def create_task
        title = params[:title].presence ||
          params.dig(:task, :title).presence
        page = current_user.pages.unscope(:order).order(:position, :created_at).first
        page ||= current_user.pages.create!(
          name: current_user.not_yet_panel_title.presence || "Not Yet",
          template: "minimal"
        )

        todo = current_user.todos.new(
          title: title.to_s.strip,
          due_date: nil,
          page: page
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
    end
  end
end
