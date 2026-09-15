require "rails_helper"

RSpec.describe TrialCleanupJob, type: :job do
  it "does nothing when HOSTED_EPHEMERAL is off" do
    user = create(:user, :trial_expired)
    described_class.perform_now
    expect(User.exists?(user.id)).to be true
  end

  it "deletes expired hosted accounts" do
    enable_hosted_ephemeral!
    expired = create(:user, :trial_expired)
    active = create(:user, :with_trial)
    paid = create(:user, :trial_expired, paid_at: Time.current)

    described_class.perform_now

    expect(User.exists?(expired.id)).to be false
    expect(User.exists?(active.id)).to be true
    expect(User.exists?(paid.id)).to be true
  end
end
