module ResourceAuthorizable
  extend ActiveSupport::Concern

  # Check if user can create pages
  def ensure_can_create_page!
    return if current_user.can_create_page?

    if current_user.hosted_ephemeral? && current_user.trial_expired? && !current_user.grandfathered_purchaser?
      redirect_to app_root_path, alert: flash_trial_expired_redirect
    else
      redirect_to app_root_path, alert: flash_page_limit_reached
    end
  end

  def ensure_trial_or_downloaded!
    return if current_user.can_use_app?

    flash_download_required
    redirect_to app_root_path
  end

  # Check if user has valid download token
  def ensure_valid_download_token!(token)
    return if token == current_user.download_token

    flash_invalid_token
    redirect_to app_root_path
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
