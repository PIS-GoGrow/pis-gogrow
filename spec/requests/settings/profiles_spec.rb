# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Profiles", type: :request do
  fixtures :admins, :companies, :providers, :users

  describe "GET /settings/profile" do
    it "shows delivery settings only for the authenticated provider" do
      sign_in providers(:tuviandita).user, role: :provider

      get settings_profile_path

      expect(inertia).to render_component("settings/profiles/show")
      expect(inertia).to have_props { |props| props["provider"]["home_delivery"] == true }
    end

    it "exposes false home_delivery when provider has disabled home delivery" do
      sign_in providers(:office_provider).user, role: :provider

      get settings_profile_path

      expect(inertia).to render_component("settings/profiles/show")
      expect(inertia).to have_props { |props| props["provider"]["home_delivery"] == false }
    end

    it "does not expose delivery settings to consumers" do
      sign_in users(:one), role: :consumer

      get settings_profile_path

      expect(inertia).to have_props { |props| props["provider"].nil? }
    end

    it "does not expose delivery settings to admins" do
      sign_in users(:admin), role: :admin

      get settings_profile_path

      expect(inertia).to have_props { |props| props["provider"].nil? }
    end

    it "redirects unauthenticated visitors to sign in" do
      get settings_profile_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "falls back to the default locale when the locale is invalid" do
      sign_in providers(:tuviandita).user, role: :provider

      get settings_profile_path, params: { locale: :provider }

      expect(response).to have_http_status(:ok)
      expect(inertia).to have_props { |props| props["provider"]["home_delivery"] == true }
    end
  end

  describe "PATCH /settings/profile" do
    it "updates only the authenticated provider's home delivery setting" do
      provider = providers(:tuviandita)
      other_provider = providers(:endulzate)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { name: provider.user.name, home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(false)
      expect(other_provider.reload.home_delivery).to be(true)
    end

    it "accepts boolean literal in home_delivery payload" do
      provider = providers(:tuviandita)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { home_delivery: false }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(false)

      patch settings_profile_path, params: { home_delivery: true }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    it "keeps home delivery unchanged when updating the provider's name" do
      provider = providers(:tuviandita)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { name: "Nuevo nombre" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    it "ignores home delivery updates outside a provider session (consumer)" do
      provider = providers(:tuviandita)
      sign_in users(:one), role: :consumer

      patch settings_profile_path, params: { name: users(:one).name, home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    it "ignores home delivery updates outside a provider session (admin)" do
      provider = providers(:tuviandita)
      sign_in users(:admin), role: :admin

      patch settings_profile_path, params: { name: users(:admin).name, home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    it "redirects unauthenticated visitors attempting to update profile" do
      patch settings_profile_path, params: { home_delivery: "0" }

      expect(response).to redirect_to(sign_in_path)
      expect(providers(:tuviandita).reload.home_delivery).to be(true)
    end

    it "does not update home delivery and returns inertia errors when user validation fails" do
      provider = providers(:tuviandita)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { name: "", home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)

      follow_redirect!
      expect(inertia).to have_props { |props| props["errors"]["name"].present? }
    end

    it "ignores unpermitted parameter bypass attempts" do
      provider = providers(:tuviandita)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: {
        name: "Nombre Valido",
        home_delivery: "0",
        admin: true,
        role: "admin",
        provider_id: 999
      }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(false)
      expect(provider.user.reload.roles).not_to include("admin")
    end
  end
end
