# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniauthCallbacks", type: :request do
  fixtures :users

  def mock_google_auth(email:, uid: "google-uid-123", name: "Test Provider")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: name, image: "https://example.com/avatar.png")
    )
  end

  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  describe "GET /auth/google_oauth2/callback" do
    it "creates the account, links a provider profile, and signs in" do
      auth = mock_google_auth(email: "new-provider@example.com")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      user = User.find_by(email: "new-provider@example.com")
      expect(user).to be_present
      expect(user.google_uid).to eq(auth.uid)
      expect(user.provider).to be_present

      expect(response).to redirect_to(dashboard_path("provider"))
      expect(cookies[:session_token]).to be_present
    end

    it "reuses the same account and provider profile on a later login" do
      auth = mock_google_auth(email: "repeat@example.com")
      OmniAuth.config.mock_auth[:google_oauth2] = auth
      get "/auth/google_oauth2/callback"
      user = User.find_by(email: "repeat@example.com")
      provider = user.provider

      get "/auth/google_oauth2/callback"

      expect(User.where(email: "repeat@example.com").count).to eq(1)
      expect(user.reload.provider).to eq(provider)
    end
  end

  describe "GET /auth/failure" do
    it "redirects to sign in with an error" do
      get "/auth/failure"

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /dashboard/provider" do
    it "rejects a signed-in user with no linked provider" do
      sign_in users(:one)

      get dashboard_path("provider")

      expect(response).to redirect_to(dashboard_path)
    end

    it "accepts a user linked to a provider profile" do
      auth = mock_google_auth(email: "linked-provider@example.com")
      OmniAuth.config.mock_auth[:google_oauth2] = auth
      get "/auth/google_oauth2/callback"

      get dashboard_path("provider")

      expect(response).to have_http_status(:success)
    end
  end
end
