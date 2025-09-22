class MarketingController < ApplicationController
  # Skip authentication for marketing pages
  skip_before_action :require_login, only: [ :landing, :pricing, :how_to, :why ]

  # Set marketing navigation flag for all marketing pages
  before_action :set_marketing_nav

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

  def why
    # Available to both logged in and anonymous users
  end

  private

  def set_marketing_nav
    @marketing_nav = true
  end
end
