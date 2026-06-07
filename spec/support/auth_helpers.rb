module AuthHelpers
  def sign_in(user)
    post login_path, params: {
      email_address: user.email_address,
      password: user.password
    }
  end

  def sign_in_as(user)
    sign_in(user)
    user
  end

  def sign_out
    delete logout_path
  end

  def current_user
    @current_user
  end

  def logged_in?
    session[:user_id].present?
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :system
end
