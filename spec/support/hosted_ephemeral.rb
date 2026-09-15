# frozen_string_literal: true

module HostedEphemeralHelpers
  def enable_hosted_ephemeral!
    Rails.application.config.x.hosted_ephemeral = true
  end

  def disable_hosted_ephemeral!
    Rails.application.config.x.hosted_ephemeral = false
  end
end

RSpec.configure do |config|
  config.include HostedEphemeralHelpers

  config.around do |example|
    previous = Rails.application.config.x.hosted_ephemeral
    Rails.application.config.x.hosted_ephemeral = false
    example.run
  ensure
    Rails.application.config.x.hosted_ephemeral = previous
  end
end
