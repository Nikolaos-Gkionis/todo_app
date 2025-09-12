class MarketingController < ApplicationController
  # Skip authentication for marketing pages
  skip_before_action :require_login, only: [ :landing, :pricing, :how_to ]

  def landing
    # Redirect to app if already logged in
    redirect_to app_root_path if logged_in?
  end

  def pricing
    # Redirect to app if already logged in
    redirect_to app_root_path if logged_in?
  end

  def how_to
    # Available to both logged in and anonymous users
  end
end
