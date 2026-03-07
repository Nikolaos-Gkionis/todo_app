module ResourceAuthorizable
  extend ActiveSupport::Concern

  # Check if user can create pages
  def ensure_can_create_page!
    return if current_user.can_create_page?

    if current_user.trial_expired? && !current_user.device_downloaded?
      redirect_to app_root_path, alert: flash_trial_expired_redirect
    else
      redirect_to app_root_path, alert: flash_page_limit_reached
    end
  end


  # Check if user has trial or downloaded app access
  def ensure_trial_or_downloaded!
    return if current_user.trial_active? || current_user.device_downloaded?

    flash_download_required
    redirect_to app_root_path
  end

  # Check if user has valid download token
  def ensure_valid_download_token!(token)
    return if token == current_user.download_token

    flash_invalid_token
    redirect_to app_root_path
  end

  # Check if user needs to complete payment for download
  def ensure_payment_completed!
    return if current_user.device_downloaded?

    if current_user.on_trial?
      flash_payment_required
      redirect_to pricing_path
    end
  end

  # Set resource and ensure ownership
  def set_and_authorize_page!
    @page = current_user.pages.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to app_root_path, alert: "Page not found or access denied."
  end

  def set_and_authorize_todo!
    @todo = @page.todos.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @page, alert: "Todo not found or access denied."
  end

  # Resource ownership helpers
  def ensure_owns_page!(page)
    return if page.user == current_user

    redirect_to app_root_path, alert: "Access denied."
  end

  def ensure_owns_todo!(todo)
    return if todo.page.user == current_user

    redirect_to todo.page, alert: "Access denied."
  end
end
