# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniauthCallbacks", type: :request do
  fixtures :users

  def mock_google_auth(email:, uid: SecureRandom.hex(8), name: "Test Provider")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: name, image: "https://example.com/avatar.png")
    )
  end

  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  describe "GET /auth/google_oauth2/callback" do
    it "rejects login if the user does not exist" do
      auth = mock_google_auth(email: "nonexistent@gmail.com")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(User.find_by(email: "nonexistent@gmail.com")).to be_nil
      expect(response).to redirect_to(sign_in_path)
    end

    it "rejects login if the user has no roles" do
      user = users(:two)
      user.update!(email: "noroles@gmail.com")

      auth = mock_google_auth(email: user.email)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(sign_in_path)
    end

    it "signs in and redirects to root when user has a single role" do
      user = users(:one)
      user.update!(email: "singlerole@gmail.com")

      auth = mock_google_auth(email: user.email)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      expect(cookies[:session_token]).to be_present
    end

    it "signs in a provider user and creates a provider session" do
      provider_user = User.create!(name: "Panadería Provider", email: "panaderia@gmail.com", password: "password123456")
      Provider.create!(user: provider_user)
      provider_user.sync_roles!

      auth = mock_google_auth(email: provider_user.email, name: provider_user.name)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      expect(provider_user.sessions.last).to be_provider
    end

    it "signs in an admin (RRHH) user and creates an admin session" do
      company = Company.first || Company.create!(name: "GoGrow", address: "18 de Julio 1006")
      admin_user = User.create!(name: "RRHH Admin", email: "rrhh-login@gogrow.com", password: "password123456")
      Admin.create!(user: admin_user, company:)
      admin_user.sync_roles!

      auth = mock_google_auth(email: admin_user.email, name: admin_user.name)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      expect(admin_user.sessions.last).to be_admin
    end

    it "signs in and redirects to edit session when user has multiple roles" do
      user = users(:one)
      user.update!(email: "multirole@gmail.com")
      Provider.create!(user: user)
      user.sync_roles!

      auth = mock_google_auth(email: user.email)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      session = user.sessions.last
      expect(response).to redirect_to(edit_session_path(session))
    end

    context "with a domain that isn't allowlisted" do
      it "rejects the login without creating an account" do
        auth = mock_google_auth(email: "someone@evil.com")
        OmniAuth.config.mock_auth[:google_oauth2] = auth

        get "/auth/google_oauth2/callback"

        expect(User.find_by(email: "someone@evil.com")).to be_nil
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with the gogrow.com domain" do
      it "allows the login for an existing user" do
        company = Company.first || Company.create!(name: "GoGrow", address: "18 de Julio 1006")
        user = User.create!(
          name: "GoGrow Staff",
          email: "someone@gogrow.com",
          password: "Secret1*3*5*123",
          verified: true
        )
        Consumer.create!(user: user, company: company, address: "Julio Herrera y Reissig 565")
        user.sync_roles!

        auth = mock_google_auth(email: "someone@gogrow.com")
        OmniAuth.config.mock_auth[:google_oauth2] = auth

        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(root_path)
        expect(cookies[:session_token]).to be_present
      end
    end
  end

  describe "GET /auth/failure" do
    it "redirects to sign in with an error" do
      get "/auth/failure"

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /provider/dashboard" do
    it "rejects a signed-in user with no linked provider" do
      sign_in users(:one), role: :consumer

      get provider_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "accepts a user linked to a provider profile" do
      user = users(:one)
      Provider.create!(user: user)
      sign_in user, role: :provider

      get provider_dashboard_path

      expect(response).to have_http_status(:success)
    end
  end
end
