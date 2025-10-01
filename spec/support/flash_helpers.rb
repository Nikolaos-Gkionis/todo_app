module FlashHelpers
  def expect_flash_message(type, message)
    expect(flash[type]).to include(message)
  end

  def expect_success_flash(message)
    expect_flash_message(:success, message)
  end

  def expect_error_flash(message)
    expect_flash_message(:alert, message)
  end

  def expect_trial_flash(message)
    expect_flash_message(:trial, message)
  end
end

RSpec.configure do |config|
  config.include FlashHelpers, type: :request
  config.include FlashHelpers, type: :controller
end
