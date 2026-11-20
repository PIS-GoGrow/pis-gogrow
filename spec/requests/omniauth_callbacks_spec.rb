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
      expect(response).to redirect_to(consumer_welcome_path)
    end

    it "rejects login if the user has no roles" do
      user = users(:two)
      user.update!(email: "noroles@gmail.com")

      auth = mock_google_auth(email: user.email)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(consumer_welcome_path)
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

    it "persists google_uid and avatar_url on first login when missing" do
      user = users(:one)
      user.update!(email: "firstlogin@gmail.com", google_uid: nil, avatar_url: nil)

      auth = mock_google_auth(email: user.email, uid: "google-uid-12345")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      user.reload
      expect(user.google_uid).to eq("google-uid-12345")
      expect(user.avatar_url).to eq("https://example.com/avatar.png")
    end

    it "does not overwrite an existing avatar_url on subsequent logins" do
      user = users(:one)
      user.update!(email: "avataruser@gmail.com", google_uid: "uid-existing", avatar_url: "https://custom.com/avatar.png")

      auth = mock_google_auth(email: user.email, uid: "uid-existing")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      expect(user.reload.avatar_url).to eq("https://custom.com/avatar.png")
    end

    it "signs in successfully by matching google_uid" do
      user = users(:one)
      user.update!(email: "byuid@gmail.com", google_uid: "persistent-uid-999")

      auth = mock_google_auth(email: user.email, uid: "persistent-uid-999")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(root_path)
      expect(user.sessions.last).to be_consumer
    end

    it "redirects with google_uid_mismatch error when google uid does not match registered account" do
      user = users(:one)
      user.update!(email: "mismatch@gmail.com", google_uid: "original-google-uid")

      auth = mock_google_auth(email: user.email, uid: "different-google-uid")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(consumer_welcome_path)
      expect(session[:inertia_errors]).to eq(auth: I18n.t("flash.google_uid_mismatch"))
    end

    it "redirects to /rrhh with mismatch error when origin is /rrhh" do
      company = Company.first || Company.create!(name: "GoGrow", address: "18 de Julio 1006")
      user = users(:one)
      user.update!(email: "adminmismatch@gmail.com", google_uid: "original-admin-uid")
      Admin.find_or_create_by!(user: user, company: company)

      auth = mock_google_auth(email: user.email, uid: "tampered-admin-uid")
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      post "/auth/google_oauth2", params: { origin: "/rrhh" }
      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to("/rrhh")
      expect(session[:inertia_errors]).to eq(auth: I18n.t("flash.google_uid_mismatch"))
    end

    it "signs in a provider user and creates a provider session" do
      provider_user = User.create!(name: "Panadería Provider", email: "panaderia@gmail.com", password: "password123456")
      Provider.create!(user: provider_user)

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

      auth = mock_google_auth(email: user.email)
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      get "/auth/google_oauth2/callback"

      session = user.sessions.last
      expect(response).to redirect_to(edit_session_path(session))
    end

    context "with a consumer and admin user" do
      let(:user) do
        company = Company.first || Company.create!(name: "GoGrow", address: "18 de Julio 1006")
        users(:one).tap do |u|
          u.update!(email: "empleado-rrhh@gmail.com")
          Admin.create!(user: u, company:)
        end
      end

      before { OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(email: user.email) }

      it "signs in as admin when coming from /rrhh" do
        post "/auth/google_oauth2", params: { origin: "/rrhh" }
        get "/auth/google_oauth2/callback"

        expect(user.sessions.last).to be_admin
        expect(response).to redirect_to(root_path)
      end

      it "signs in as consumer when coming from /consumidor" do
        post "/auth/google_oauth2", params: { origin: "/consumidor" }
        get "/auth/google_oauth2/callback"

        expect(user.sessions.last).to be_consumer
        expect(response).to redirect_to(root_path)
      end

      it "rejects a user without the role of the entry screen" do
        user.admin.destroy!

        post "/auth/google_oauth2", params: { origin: "/rrhh" }
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to("/rrhh")
        expect(user.sessions).to be_empty
      end

      it "asks for the role when the entry point is unknown" do
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(edit_session_path(user.sessions.last))
      end
    end

    context "with a domain that isn't allowlisted" do
      it "rejects the login without creating an account" do
        auth = mock_google_auth(email: "someone@evil.com")
        OmniAuth.config.mock_auth[:google_oauth2] = auth

        get "/auth/google_oauth2/callback"

        expect(User.find_by(email: "someone@evil.com")).to be_nil
        expect(response).to redirect_to(consumer_welcome_path)
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

        auth = mock_google_auth(email: "someone@gogrow.com")
        OmniAuth.config.mock_auth[:google_oauth2] = auth

        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(root_path)
        expect(cookies[:session_token]).to be_present
      end
    end
  end

  describe "errors from an entry screen" do
    it "sends a failed RRHH login back to /rrhh" do
      OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(email: "nadie@gmail.com")
      post "/auth/google_oauth2", params: { origin: "/rrhh" }
      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to("/rrhh")
    end

    it "sends a rejected consumer login back to /consumidor" do
      OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(email: "nadie@gmail.com")
      post "/auth/google_oauth2", params: { origin: "/consumidor" }
      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to("/consumidor")
    end

    it "ignores an origin that is not an entry screen" do
      OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(email: "nadie@gmail.com")
      post "/auth/google_oauth2", params: { origin: "https://evil.com/x" }
      get "/auth/google_oauth2/callback"

      expect(response).to redirect_to(consumer_welcome_path)
    end
  end

  describe "GET /auth/failure" do
    it "redirects to sign in with an error" do
      get "/auth/failure"

      expect(response).to redirect_to(consumer_welcome_path)
    end
  end

  describe "GET /provider/inicio" do
    it "rejects a signed-in user with no linked provider" do
      sign_in users(:one), role: :consumer

      get provider_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "accepts a user linked to a provider profile" do
      user = users(:one)
      Provider.create!(user: user, onboarding_completed_at: Time.current)
      sign_in user, role: :provider

      get provider_dashboard_path

      expect(response).to have_http_status(:success)
    end
  end
end
