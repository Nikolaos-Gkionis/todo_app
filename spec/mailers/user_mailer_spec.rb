# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, :with_trial, name: "Ada") }

  describe "#trial_expiring_soon" do
    subject(:mail) { described_class.trial_expiring_soon(user) }

    it "sends people to pricing, not a pre-purchase download" do
      expect(mail.body.encoded).to include("View pricing")
      expect(mail.body.encoded).to include("example.com/pricing")
      expect(mail.body.encoded).not_to include("download the app anytime")
      expect(mail.body.encoded).to include("Omarchy")
    end
  end

  describe "#download_reminder" do
    subject(:mail) { described_class.download_reminder(user) }

    it "asks them to purchase before PWA install" do
      expect(mail.subject).to include("one-time purchase")
      expect(mail.body.encoded).to include("View pricing")
      expect(mail.body.encoded).to include("cannot install before you pay")
    end
  end
end
