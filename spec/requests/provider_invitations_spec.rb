# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider invitations", type: :request do
  let(:company) { companies(:gogrow) }
  let(:strong_password) { "Nueva-Clave-2026-ok!" }
  let!(:user) { Providers::Invite.call(name: "Ana Proveedora", email: "ana@proveedor.com", company: company) }
  let(:token) { "#{user.id}.#{OtpCode.find_by!(user: user, purpose: :invitation).code}" }

  def open_invitation(token: self.token)
    get provider_invitation_path, params: { token: token }
  end

  def register(password: strong_password, confirmation: strong_password)
    patch provider_invitation_path, params: { password: password, password_confirmation: confirmation }
  end

  describe "GET /provider/invitation?token=" do
    it "accepts the link and moves to a clean URL with the registration form" do
      open_invitation

      expect(response).to redirect_to(provider_invitation_path)
      follow_redirect!
      expect(inertia).to render_component("provider_invitations/show")
      expect(inertia).to have_props(email: "ana@proveedor.com")
    end

    it "keeps the link valid until the registration is finished" do
      open_invitation
      reset!
      open_invitation

      expect(response).to redirect_to(provider_invitation_path)
    end

    it "rejects a wrong token" do
      open_invitation(token: "#{user.id}.#{'0' * 32}")

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.invitation_invalid"))
    end

    it "rejects the token of another user" do
      other = Providers::Invite.call(name: "Beto", email: "beto@proveedor.com", company: company)
      other_code = OtpCode.find_by!(user: other, purpose: :invitation).code

      open_invitation(token: "#{user.id}.#{other_code}")

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects an expired invitation" do
      link = token

      travel(8.days) { open_invitation(token: link) }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects a malformed or empty token" do
      [ "basura", "999999.abc", ".", "#{user.id}." ].each do |bad|
        open_invitation(token: bad)
        expect(response).to redirect_to(provider_sign_in_path)
      end
    end

    it "rejects the link once the provider already registered" do
      link = token
      user.update!(verified: true)

      open_invitation(token: link)

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "limits the attempts per IP" do
      freeze_time do
        20.times { open_invitation(token: "basura") }

        open_invitation

        expect(flash[:alert]).to eq(I18n.t("flash.too_many_attempts"))
      end
    end
  end

  describe "GET /provider/invitation" do
    it "is closed without an accepted link" do
      get provider_invitation_path

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.invitation_invalid"))
    end

    it "redirects an authenticated user" do
      sign_in users(:provider_user)

      get provider_invitation_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects an authenticated consumer visiting the invitation link to the root path" do
      sign_in users(:one), role: :consumer

      open_invitation

      expect(response).to redirect_to(root_path)
    end

    it "redirects an authenticated admin visiting the invitation link to the root path" do
      sign_in users(:admin), role: :admin

      open_invitation

      expect(response).to redirect_to(root_path)
    end

    it "only exposes the email in Inertia props and does not leak sensitive attributes" do
      open_invitation
      follow_redirect!

      expect(inertia.props).to have_key(:email)
      expect(inertia.props[:email]).to eq("ana@proveedor.com")
      expect(inertia.props).not_to have_key(:nonce)
      expect(inertia.props).not_to have_key(:code)
      expect(inertia.props).not_to have_key(:password_digest)
    end
  end

  describe "PATCH /provider/invitation" do
    before { open_invitation }

    it "sets the password, verifies the account and consumes the invitation" do
      register

      expect(response).to redirect_to(provider_onboarding_path)
      expect(user.reload.authenticate(strong_password)).to be_truthy
      expect(user).to be_verified
      expect(OtpCode.pending?(user, :invitation)).to be(false)
    end

    it "signs the provider in and sends them to the onboarding" do
      register

      expect(response).to redirect_to(provider_onboarding_path)
      expect(user.sessions.last.role).to eq("provider")

      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "does not let the same link register again" do
      register
      reset!
      open_invitation

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "cannot be used without an accepted link" do
      reset!
      register

      expect(response).to redirect_to(provider_sign_in_path)
      expect(user.reload).not_to be_verified
    end

    it "stops working if the invitation expired meanwhile" do
      travel(8.days) { register }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(user.reload).not_to be_verified
    end

    it "rejects a weak password and keeps the invitation open" do
      register(password: "corta", confirmation: "corta")

      follow_redirect!
      expect(inertia.props[:errors][:password]).to be_present
      expect(user.reload).not_to be_verified
      expect(OtpCode.pending?(user, :invitation)).to be(true)
    end

    it "rejects a confirmation that does not match" do
      register(confirmation: "Distinta-Clave-2026!!")

      follow_redirect!
      expect(inertia.props[:errors][:password_confirmation]).to be_present
      expect(user.reload).not_to be_verified
    end

    it "ignores parameters attempting to change the email or inject admin roles" do
      patch provider_invitation_path, params: {
        password: strong_password,
        password_confirmation: strong_password,
        email: "hacker@evil.com",
        roles: [ "admin" ]
      }

      expect(response).to redirect_to(provider_onboarding_path)
      expect(user.reload.email).to eq("ana@proveedor.com")
      expect(user.roles).to eq([ "provider" ])
    end

    it "rejects a blank password returning errors and leaving user unverified" do
      patch provider_invitation_path, params: { password: "", password_confirmation: "" }

      expect(response).to redirect_to(provider_invitation_path)
      follow_redirect!
      expect(inertia.props[:errors][:password]).to be_present
      expect(user.reload).not_to be_verified
    end
  end
end
