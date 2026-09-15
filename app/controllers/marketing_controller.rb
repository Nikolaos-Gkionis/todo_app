class MarketingController < ApplicationController
  skip_before_action :require_login, only: [ :landing, :how_to, :why, :privacy, :terms ]
  skip_before_action :block_expired_hosted_week!, only: [ :landing, :how_to, :why, :privacy, :terms ]

  before_action :set_marketing_nav

  def landing
    redirect_to app_root_path if can_access_app_dashboard?
  end

  def how_to
  end

  def why
  end

  def privacy
  end

  def terms
  end

  private

  def set_marketing_nav
    @marketing_nav = true
  end
end
