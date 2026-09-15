# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, :with_trial, name: "Ada") }

  describe "#trial_expiring_soon" do
    subject(:mail) { described_class.trial_expiring_soon(user) }

    it "points people at the source repo, not a shop" do
      expect(mail.subject).to include("week ends")
      expect(mail.body.encoded).to include("github.com/Nikolaos-Gkionis/todo_app")
      expect(mail.body.encoded).not_to include("View pricing")
    end
  end

  describe "#welcome_trial" do
    subject(:mail) { described_class.welcome_trial(user) }

    it "welcomes them without a purchase pitch" do
      expect(mail.subject).to include("Welcome")
      expect(mail.body.encoded).not_to include("£9.99")
    end
  end
end
