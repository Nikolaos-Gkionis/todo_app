# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactController, type: :controller do
  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "renders the contact form" do
      get :new
      expect(response).to render_template(:new)
    end

    it "does not require login" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    context "with honeypot filled (bot)" do
      it "silently pretends success without sending email" do
        expect(ContactMailer).not_to receive(:contact_form)

        post :create, params: {
          name: "Spammer",
          email: "spam@example.com",
          message: "Buy stuff",
          website: "https://spam.com"
        }

        expect(response).to redirect_to(contact_path)
        expect(flash[:notice]).to eq("Thanks! We'll get back to you.")
      end
    end

    context "with valid params" do
      before do
        allow(ContactMailer).to receive(:contact_form).and_return(double(deliver_later: true))
      end

      it "sends the contact email and redirects" do
        post :create, params: {
          name: "Jane",
          email: "jane@example.com",
          message: "Hello, I have a question."
        }

        expect(ContactMailer).to have_received(:contact_form).with(
          hash_including(name: "Jane", email: "jane@example.com", message: "Hello, I have a question.")
        )
        expect(response).to redirect_to(contact_path)
        expect(flash[:notice]).to eq("Thanks! We'll get back to you soon.")
      end
    end

    context "with missing email" do
      it "renders form with error" do
        post :create, params: {
          name: "Jane",
          email: "",
          message: "Hello"
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Please provide your email and message.")
      end
    end

    context "with missing message" do
      it "renders form with error" do
        post :create, params: {
          name: "Jane",
          email: "jane@example.com",
          message: ""
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Please provide your email and message.")
      end
    end

    context "with invalid email" do
      it "renders form with error" do
        post :create, params: {
          name: "Jane",
          email: "not-an-email",
          message: "Hello"
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Please enter a valid email address.")
      end
    end
  end
end
