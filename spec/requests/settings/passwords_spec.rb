# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Passwords", type: :request do
  fixtures :users

  before { sign_in users(:one) }

  describe "GET /settings/password" do
    it "renders the password settings page" do
      get settings_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /settings/password" do
    context "with valid password challenge" do
      it "updates the password" do
        patch settings_password_path, params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*",
          password_challenge: "Secret1*3*5*"
        }
        expect(response).to redirect_to(settings_password_path)
        expect(flash[:notice]).to eq("Tu contraseña fue modificada")
      end
    end

    context "with invalid password challenge" do
      it "does not update the password and returns inertia errors" do
        patch settings_password_path, params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*",
          password_challenge: "wrongpassword"
        }
        expect(response).to redirect_to(settings_password_path)
        expect(session[:inertia_errors]).to eq(password_challenge: [ I18n.t("errors.messages.invalid") ])
      end
    end
  end

  describe "PATCH /settings/password as a provider" do
    let(:provider) { users(:provider_user) }

    before { sign_in provider }

    it "requires the provider password policy" do
      patch settings_password_path, params: {
        password: "NewPassword1*3*",
        password_confirmation: "NewPassword1*3*",
        password_challenge: "Secret1*3*5*"
      }

      expect(session[:inertia_errors][:password]).to be_present
      expect(provider.reload.authenticate("NewPassword1*3*")).to be(false)
    end

    it "accepts a password that meets the policy" do
      patch settings_password_path, params: {
        password: "Nueva-Clave-2026-ok!",
        password_confirmation: "Nueva-Clave-2026-ok!",
        password_challenge: "Secret1*3*5*"
      }

      expect(flash[:notice]).to eq("Tu contraseña fue modificada")
      expect(provider.reload.authenticate("Nueva-Clave-2026-ok!")).to be_truthy
    end
  end
end
