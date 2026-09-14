# frozen_string_literal: true

module Api
  module V1
    # Desktop helper writes. Named under Api::V1 so it does not collide
    # with the website TodosController (session + Turbo).
    class TodosController < BaseController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      # DELETE /api/v1/todos/:id
      def destroy
        todo = current_user.todos.find(params[:id])
        todo.destroy!
        render json: { ok: true, id: todo.id }
      end

      private

      def render_not_found
        render json: { error: "not_found" }, status: :not_found
      end
    end
  end
end
