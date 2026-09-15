# Shared examples for common test patterns

RSpec.shared_examples "requires authentication" do
  context "when user is not logged in" do
    it "redirects to login page" do
      subject
      expect(response).to redirect_to(login_path)
    end
  end
end

RSpec.shared_examples "requires trial access" do
  context "when the hosted week has ended" do
    let(:user) { create(:user, :trial_expired) }

    before do
      enable_hosted_ephemeral!
      sign_in(user)
    end

    it "redirects home" do
      subject
      expect(response).to redirect_to(root_path)
    end
  end
end

RSpec.shared_examples "allows downloaded app users" do
  context "when user has a grandfathered purchase" do
    let(:user) { create(:user, :downloaded_app) }

    before { sign_in(user) }

    it "allows access" do
      subject
      expect(response).not_to redirect_to(root_path)
    end
  end
end

RSpec.shared_examples "validates presence of" do |attribute|
  it "validates presence of #{attribute}" do
    subject.send("#{attribute}=", nil)
    expect(subject).not_to be_valid
    expect(subject.errors[attribute]).to include("can't be blank")
  end
end

RSpec.shared_examples "validates uniqueness of" do |attribute|
  it "validates uniqueness of #{attribute}" do
    existing_record = create(described_class.name.underscore.to_sym)
    subject.send("#{attribute}=", existing_record.send(attribute))
    expect(subject).not_to be_valid
    expect(subject.errors[attribute]).to include("has already been taken")
  end
end
