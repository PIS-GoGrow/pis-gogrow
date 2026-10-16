# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  fixtures :users, :consumers, :providers, :admins, :companies

  describe "GET /" do
    it "shows the consumer welcome" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DEV_LOGIN_ENABLED", "false").and_return("false")

      get root_path

      expect(inertia).to render_component("home/index")
      expect(inertia).to have_props(variant: "consumer", dev_login_enabled: false)
    end

    it "shows the password form when the test login is enabled" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DEV_LOGIN_ENABLED", "false").and_return("true")

      get root_path

      expect(inertia).to have_props(dev_login_enabled: true)
    end

    it "sends a signed-in consumer to the dashboard" do
      sign_in users(:one), role: :consumer
      get root_path
      expect(response).to redirect_to(dashboard_path)
    end

    it "sends a signed-in provider to the provider dashboard" do
      sign_in users(:provider_user), role: :provider
      get root_path
      expect(response).to redirect_to(provider_dashboard_path)
    end

    it "sends a signed-in admin to the admin dashboard" do
      sign_in users(:admin), role: :admin
      get root_path
      expect(response).to redirect_to(admin_dashboard_path)
    end

    it "sends an unknown role to the sign in page" do
      session = users(:one).sessions.create!(role: :consumer)
      session.update_column(:role, 999) # invalid/unknown role
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

      get root_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /proveedor" do
    it "redirects to /provider to maintain route consistency" do
      get provider_welcome_path

      expect(response).to redirect_to("/provider")
    end
  end

  describe "GET /rrhh" do
    it "shows the admin welcome" do
      get admin_welcome_path

      expect(inertia).to render_component("home/index")
      expect(inertia).to have_props(variant: "admin")
    end

    it "redirects an already authenticated admin to admin dashboard" do
      sign_in users(:admin), role: :admin
      get admin_welcome_path
      expect(response).to redirect_to(admin_dashboard_path)
    end
  end
end
