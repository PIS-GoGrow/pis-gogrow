# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Profiles", type: :request do
  fixtures :admins, :companies, :providers, :users

  describe "GET /configuracion/perfil" do
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

  describe "PATCH /configuracion/perfil" do
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

    it "guarda un celular uruguayo escrito sin código de país en formato internacional" do
      patch settings_profile_path, params: { name: user.name, phone: "099 123 456" }

      expect(user.reload.phone).to eq("+59899123456")
    end

    it "respeta el código de país de un celular extranjero" do
      patch settings_profile_path, params: { name: user.name, phone: "+54 9 11 2345-6789" }

      expect(user.reload.phone).to eq("+5491123456789")
    end

    it "rechaza un teléfono fijo" do
      patch settings_profile_path, params: { name: user.name, phone: "2900 1234" }

      expect(user.reload.phone).to be_nil
      follow_redirect!
      expect(inertia.props[:errors]).to include("phone")
    end

    it "registra el cambio de teléfono" do
      patch settings_profile_path, params: { name: user.name, phone: "+59899123456" }

      expect(user.audit_logs.sole.changeset).to eq("phone" => [ nil, "+59899123456" ])
    end

    it "registra el cambio de entregas a domicilio" do
      patch settings_profile_path, params: { home_delivery: false }

      expect(providers(:tuviandita).audit_logs.sole).to have_attributes(user:, changeset: { "home_delivery" => [ true, false ] })
    end
  end
end
