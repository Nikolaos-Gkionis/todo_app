class MarketingController < ApplicationController
  # Skip authentication for marketing pages
  skip_before_action :require_login, only: [ :landing, :pricing, :how_to, :why, :privacy, :terms ]

  # Set marketing navigation flag for all marketing pages
  before_action :set_marketing_nav

  def landing
    # Logged-in users with access go straight to the app; expired trials stay here (and use Pricing to pay)
    redirect_to app_root_path if can_access_app_dashboard?
  end

  def pricing
    redirect_to app_root_path if can_access_app_dashboard?
  end

  def how_to
    # Available to both logged in and anonymous users
  end

  def why
    # Available to both logged in and anonymous users
  end

  def privacy
    # Available to both logged in and anonymous users
  end

  def terms
    # Available to both logged in and anonymous users
  end

  private

  def set_marketing_nav
    @marketing_nav = true
  end
end
