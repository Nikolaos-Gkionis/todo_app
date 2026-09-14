# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_desktop_token!, only: [ :login ]

      # POST /api/v1/auth/login
      # Body: { email / email_address, password }
      def login
        email = params[:email].presence || params[:email_address].presence
        password = params[:password].to_s

        user = User.find_by("LOWER(email_address) = ?", email.to_s.downcase)

        unless user&.authenticate(password)
          return render json: { error: "invalid_credentials", message: "Invalid email or password." }, status: :unauthorized
        end

        unless user.can_install_pwa?
          return render json: {
            error: "paid_required",
            message: "Desktop helpers are for paid peponi.to accounts. Purchase or finish install, then try again."
          }, status: :forbidden
        end

        token = user.issue_desktop_api_token!

        render json: {
          token: token,
          expires_at: user.desktop_api_token_expires_at&.iso8601,
          user: {
            email: user.email_address,
            name: user.display_name,
            app_title: user.app_title,
            not_yet_panel_title: user.not_yet_panel_title
          }
        }
      end

      # DELETE /api/v1/auth/logout
      def logout
        current_user.revoke_desktop_api_token!
        render json: { ok: true }
      end

      # GET /api/v1/auth/status
      def status
        render json: {
          authenticated: true,
          paid: current_user.can_install_pwa?,
          user: {
            email: current_user.email_address,
            name: current_user.display_name,
            app_title: current_user.app_title,
            not_yet_panel_title: current_user.not_yet_panel_title
          },
          expires_at: current_user.desktop_api_token_expires_at&.iso8601
        }
      end
    end
  end
end
