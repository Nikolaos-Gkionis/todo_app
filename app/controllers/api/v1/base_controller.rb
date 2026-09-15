# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_desktop_token!

      private

      attr_reader :current_user

      def authenticate_desktop_token!
        raw = bearer_token
        @current_user = User.find_by_desktop_api_token(raw)

        return if @current_user

        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        return header.delete_prefix("Bearer ").strip if header.start_with?("Bearer ")

        # Also accept X-Peponi-Token for simple curl / scripts
        request.headers["X-Peponi-Token"].presence
      end

      def require_signed_in_desktop!
        return if current_user

        render json: { error: "unauthorized", message: "Sign in to copy tasks onto this machine. On Omarchy you can also stay local with no account." }, status: :forbidden
      end

      def serialize_todo(todo)
        {
          id: todo.id,
          title: todo.title.to_s.strip,
          completed: todo.completed == true,
          list: todo.page&.name.to_s,
          is_visual_break: todo.is_visual_break?
        }
      end
    end
  end
end
