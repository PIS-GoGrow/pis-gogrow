# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Profiles", type: :request do
  fixtures :admins, :companies, :providers, :users

  describe "GET /configuracion/perfil" do
    it "shows the profile without provider delivery settings" do
      sign_in providers(:tuviandita).user, role: :provider

      get settings_profile_path

      expect(inertia).to render_component("settings/profiles/show")
      expect(inertia).to have_no_prop(:provider)
    end

    it "redirects unauthenticated visitors to sign in" do
      get settings_profile_path

      expect(response).to redirect_to(consumer_welcome_path)
    end

    it "falls back to the default locale when the locale is invalid" do
      sign_in providers(:tuviandita).user, role: :provider

      get settings_profile_path, params: { locale: :provider }

      expect(response).to have_http_status(:ok)
      expect(inertia).to have_no_prop(:provider)
    end
  end

  describe "PATCH /configuracion/perfil" do
    it "ignores home delivery because it is configured from the provider account" do
      provider = providers(:tuviandita)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { name: provider.user.name, home_delivery: "0" }

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

    it "redirects unauthenticated visitors attempting to update profile" do
      patch settings_profile_path, params: { home_delivery: "0" }

      expect(response).to redirect_to(consumer_welcome_path)
      expect(providers(:tuviandita).reload.home_delivery).to be(true)
    end

    it "returns inertia errors when user validation fails" do
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
      expect(provider.reload.home_delivery).to be(true)
      expect(provider.user.reload.roles).not_to include("admin")
    end
  end

  describe "PATCH /configuracion/perfil as RRHH" do
    it "no deja cambiar el email aunque venga en el pedido" do
      admin = users(:admin)
      sign_in admin, role: :admin

      patch settings_profile_path, params: { name: "RRHH Nuevo", email: "otro@example.com" }

      expect(response).to redirect_to(settings_profile_path)
      expect(admin.reload).to have_attributes(name: "RRHH Nuevo", email: "admin@example.com")
    end
  end

  describe "PATCH /configuracion/perfil phone" do
    let(:user) { providers(:tuviandita).user }

    before { sign_in user, role: :provider }

    it "guarda el teléfono sin espacios ni guiones" do
      patch settings_profile_path, params: { name: user.name, phone: "+598 99 123-456" }

      expect(user.reload.phone).to eq("+59899123456")
      follow_redirect!
      expect(inertia).to have_props(phone: "+59899123456")
    end

    it "rechaza un teléfono inválido" do
      patch settings_profile_path, params: { name: user.name, phone: "llamame" }

      expect(user.reload.phone).to be_nil
      follow_redirect!
      expect(inertia.props[:errors]).to include("phone")
    end

    it "registra el cambio de teléfono" do
      patch settings_profile_path, params: { name: user.name, phone: "099123456" }

      expect(user.audit_logs.sole.changeset).to eq("phone" => [ nil, "099123456" ])
    end
  end
end
