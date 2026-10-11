# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ProviderSessions", type: :request do
  let(:provider) { users(:provider_user) }
  let(:password) { "Secret1*3*5*" }

  describe "GET /proveedores" do
    it "renders the provider sign in page" do
      get provider_sign_in_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider_sessions/new")
    end

    it "redirects authenticated users" do
      sign_in provider

      get provider_sign_in_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /proveedores" do
    it "opens a provider session and goes to the provider dashboard" do
      post provider_sign_in_path, params: { email: provider.email, password: password }

      expect(response).to redirect_to(provider_dashboard_path)
      expect(provider.sessions.last.role).to eq("provider")

      get provider_dashboard_path
      expect(response).to have_http_status(:success)
    end

    it "ignores case and spaces in the email" do
      post provider_sign_in_path, params: { email: " #{provider.email.upcase} ", password: password }

      expect(response).to redirect_to(provider_dashboard_path)
    end

    it "rejects a wrong password" do
      post provider_sign_in_path, params: { email: provider.email, password: "wrong" }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.incorrect_credentials"))
      expect(provider.sessions.count).to eq(0)
    end

    it "rejects a correct password from an account that is not a provider" do
      post provider_sign_in_path, params: { email: users(:one).email, password: password }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.incorrect_credentials"))
    end

    it "rejects a provider that has not finished the registration" do
      provider.update!(verified: false)

      post provider_sign_in_path, params: { email: provider.email, password: password }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(provider.sessions.count).to eq(0)
    end

    it "answers the same for an unknown email" do
      post provider_sign_in_path, params: { email: "nadie@example.com", password: password }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.incorrect_credentials"))
    end

    it "blocks an email after too many attempts, even with the right password" do
      10.times { post provider_sign_in_path, params: { email: provider.email, password: "wrong" } }

      post provider_sign_in_path, params: { email: provider.email, password: password }

      expect(flash[:alert]).to eq(I18n.t("flash.too_many_attempts"))
      expect(provider.sessions.count).to eq(0)
    end

    it "blocks an IP after too many attempts across different emails" do
      20.times { |i| post provider_sign_in_path, params: { email: "u#{i}@example.com", password: "wrong" } }

      post provider_sign_in_path, params: { email: provider.email, password: password }

      expect(flash[:alert]).to eq(I18n.t("flash.too_many_attempts"))
    end
  end
end
