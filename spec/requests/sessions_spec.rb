# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  fixtures :users

  describe "GET /sign_in" do
    it "renders the sign in page" do
      get sign_in_path
      expect(response).to have_http_status(:success)
    end

    it "redirects authenticated users" do
      sign_in users(:one)
      get sign_in_path
      expect(response).to redirect_to(root_path)
    end

    it "hides the password form unless the test login is enabled" do
      get sign_in_path

      expect(inertia).to render_component("sessions/new")
      expect(inertia.props[:dev_login_enabled]).to be(false)
    end

    it "shows the password form when the test login is enabled" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DEV_LOGIN_ENABLED", "false").and_return("true")

      get sign_in_path

      expect(inertia.props[:dev_login_enabled]).to be(true)
    end
  end

  describe "POST /sign_in" do
    context "with valid credentials" do
      it "signs in and sets a session cookie" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(root_path)
        expect(cookies[:session_token]).to be_present

        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid credentials" do
      it "redirects back with an alert" do
        post sign_in_path, params: { email: users(:one).email, password: "wrongpassword" }
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq("El correo electrónico o la contraseña son incorrectos")

        get dashboard_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with a provider account" do
      it "opens the session with the provider role" do
        post sign_in_path, params: { email: users(:provider_user).email, password: "Secret1*3*5*" }

        expect(response).to redirect_to(root_path)
        expect(users(:provider_user).sessions.last.role).to eq("provider")
      end
    end

    context "with an HR account" do
      it "opens the session with the admin role" do
        post sign_in_path, params: { email: users(:admin).email, password: "Secret1*3*5*" }

        expect(response).to redirect_to(root_path)
        expect(users(:admin).sessions.last.role).to eq("admin")
      end
    end

    context "when user has no profile" do
      it "denies access and redirects to sign in" do
        post sign_in_path, params: { email: users(:two).email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq(I18n.t("flash.role_not_available"))
      end
    end
  end

  describe "DELETE /sessions/:id" do
    it "destroys the session" do
      sign_in users(:one)
      session_record = users(:one).sessions.last
      delete session_path(session_record)
      expect(response).to redirect_to(root_path)
      expect(Session.exists?(session_record.id)).to be(false)
    end
  end
end
