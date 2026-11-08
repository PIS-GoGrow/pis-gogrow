# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider welcomes", type: :request do
  fixtures :companies, :users

  let(:company) { companies(:gogrow) }
  let!(:user) { Providers::Invite.call(name: "Ana Proveedora", email: "ana@proveedor.com", company: company) }
  let(:token) { "#{user.id}.#{OtpCode.find_by!(user: user, purpose: :invitation).code}" }
  let(:company_token) { company.signed_id(purpose: :provider_invitation) }

  describe "GET /proveedor/bienvenida" do
    it "greets the invited provider and points to the registration" do
      get provider_welcome_path, params: { token: token, company: company_token }

      expect(inertia).to render_component("provider_welcomes/show")
      expect(inertia).to have_props(
        username: "Ana Proveedora",
        company_name: company.name,
        invitation_path: provider_invitation_path(token: token)
      )
    end

    it "does not consume the invitation" do
      get provider_welcome_path, params: { token: token, company: company_token }

      expect(OtpCode.pending?(user, :invitation)).to be(true)
    end

    it "redirects to sign in when parameters are missing" do
      get provider_welcome_path

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects a malformed token without dot separator" do
      get provider_welcome_path, params: { token: "invalidtokenformat", company: company_token }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects a wrong token" do
      get provider_welcome_path, params: { token: "#{user.id}.#{'0' * 32}", company: company_token }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects a company that was not signed for the invitation" do
      get provider_welcome_path, params: { token: token, company: company.signed_id }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects a provider that already registered" do
      user.update_column(:verified, true)

      get provider_welcome_path, params: { token: token, company: company_token }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "redirects an already authenticated user" do
      sign_in users(:one), role: :consumer

      get provider_welcome_path, params: { token: token, company: company_token }

      expect(response).to redirect_to(root_path)
    end

    it "redirects an authenticated admin to root" do
      sign_in users(:admin), role: :admin

      get provider_welcome_path, params: { token: token, company: company_token }

      expect(response).to redirect_to(root_path)
    end

    it "redirects an authenticated provider to root" do
      sign_in users(:provider_user), role: :provider

      get provider_welcome_path, params: { token: token, company: company_token }

      expect(response).to redirect_to(root_path)
    end

    it "rejects when company parameter is a raw database ID instead of signed token" do
      get provider_welcome_path, params: { token: token, company: company.id }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects when token contains non-numeric user id" do
      get provider_welcome_path, params: { token: "abc.123456", company: company_token }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rejects when token references a user that is not a provider" do
      consumer_user = users(:one)
      consumer_code = OtpCode.issue(consumer_user, :invitation)
      invalid_role_token = "#{consumer_user.id}.#{consumer_code.code}"

      get provider_welcome_path, params: { token: invalid_role_token, company: company_token }

      expect(response).to redirect_to(provider_sign_in_path)
    end
  end
end
