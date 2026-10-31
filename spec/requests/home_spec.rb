# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  fixtures :users, :consumers, :providers, :admins, :companies

  describe "GET /" do
    it "redirects to /consumidor when signed out" do
      get root_path

      expect(response).to redirect_to("/consumidor")
    end

    it "keeps the flash across the redirect" do
      user = users(:one)
      sign_in user, role: :consumer
      delete session_path(user.sessions.last)
      expect(response).to redirect_to(root_path)

      follow_redirect!
      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.session_logged_out"))
    end
  end

  describe "GET /consumidor" do
    it "shows the consumer welcome" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DEV_LOGIN_ENABLED", "false").and_return("false")

      get consumer_welcome_path

      expect(inertia).to render_component("home/index")
      expect(inertia).to have_props(variant: "consumer", dev_login_enabled: false)
    end

    it "shows the password form when the test login is enabled" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DEV_LOGIN_ENABLED", "false").and_return("true")

      get consumer_welcome_path

      expect(inertia).to have_props(dev_login_enabled: true)
    end
  end

  describe "GET / signed in" do
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

    it "shows the welcome when the session role is unknown" do
      session = users(:one).sessions.create!(role: :consumer)
      session.update_column(:role, 999) # invalid/unknown role
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

      get consumer_welcome_path
      expect(inertia).to render_component("home/index")
    end
  end

  describe "GET /provider" do
    it "redirects to /proveedor to maintain route consistency" do
      get "/provider"

      expect(response).to redirect_to("/proveedor")
    end
  end

  describe "GET /proveedor" do
    it "shows the provider welcome" do
      get "/proveedor"

      expect(inertia).to render_component("home/index")
      expect(inertia).to have_props(variant: "provider")
    end

    it "redirects an already authenticated provider to provider dashboard" do
      sign_in users(:provider_user), role: :provider
      get "/proveedor"
      expect(response).to redirect_to(provider_dashboard_path)
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
