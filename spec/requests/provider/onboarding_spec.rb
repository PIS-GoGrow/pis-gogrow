# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::Onboarding", type: :request do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider) { providers(:tuviandita) }

  before { provider.update!(onboarding_completed_at: nil) }

  describe "el guard de onboarding" do
    it "manda al onboarding a un proveedor sin configurar" do
      sign_in provider.user, role: :provider

      get provider_dashboard_path

      expect(response).to redirect_to(provider_onboarding_path)
    end

    it "deja pasar a un proveedor que ya lo completó" do
      provider.update!(onboarding_completed_at: Time.current)
      sign_in provider.user, role: :provider

      get provider_dashboard_path

      expect(inertia).to render_component("provider/dashboard/index")
    end
  end

  describe "GET /provider/onboarding" do
    before { sign_in provider.user, role: :provider }

    it "arranca en el primer paso" do
      get provider_onboarding_path

      expect(inertia).to render_component("provider/onboarding/show")
      expect(inertia).to have_props { |props| props["step"] == "1" }
    end

    it "muestra el paso pedido en la URL" do
      get provider_onboarding_path(step: 4)

      expect(inertia).to have_props do |props|
        props["step"] == "4" && props["notification_configurations"].any?
      end
    end

    it "muestra el cierre cuando ya está completo" do
      provider.update!(onboarding_completed_at: Time.current)

      get provider_onboarding_path(step: 1)

      expect(inertia).to have_props { |props| props["step"] == "done" }
    end
  end

  describe "PATCH /provider/onboarding" do
    before { sign_in provider.user, role: :provider }

    let(:payment_params) do
      {
        bank_name: "BROU",
        bank_account_type: "savings",
        bank_account_number: "001234567-00001",
        bank_account_holder: "Tu Vianda SRL",
        tax_id: "212345670012"
      }
    end

    it "guarda los datos de cobro y avanza al paso 2" do
      patch provider_onboarding_path, params: { step: 1, commit: "continue", provider: payment_params }

      expect(response).to redirect_to(provider_onboarding_path(step: 2))
      expect(provider.reload.bank_name).to eq("BROU")
    end

    it "no avanza cuando los datos de cobro son inválidos" do
      patch provider_onboarding_path, params: { step: 1, commit: "continue", provider: { bank_name: "BROU" } }

      expect(response).to redirect_to(provider_onboarding_path(step: 1))
      expect(provider.reload.bank_name).to be_nil
    end

    it "omite un paso sin guardar nada" do
      patch provider_onboarding_path, params: { step: 1, commit: "skip", provider: { bank_name: "BROU" } }

      expect(response).to redirect_to(provider_onboarding_path(step: 2))
      expect(provider.reload.bank_name).to be_nil
    end

    it "guarda la hora de cierre en el paso 2" do
      patch provider_onboarding_path, params: { step: 2, commit: "continue", order_deadline: "18:30" }

      expect(response).to redirect_to(provider_onboarding_path(step: 3))
      expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("18:30")
    end

    it "guarda las entregas en el paso 3" do
      patch provider_onboarding_path, params: { step: 3, commit: "continue", home_delivery: false }

      expect(response).to redirect_to(provider_onboarding_path(step: 4))
      expect(provider.reload.home_delivery).to be(false)
    end

    it "suscribe a notificaciones y completa el onboarding en el paso 4" do
      config = Notification::Configuration.for_role(:provider).where(configurable: true).first

      patch provider_onboarding_path, params: { step: 4, commit: "continue", subscribed_ids: [ config.id ] }

      expect(response).to redirect_to(provider_onboarding_path(step: "done"))
      expect(config.reload.users).to include(provider.user)
      expect(provider.reload.onboarding_completed_at).to be_present
    end
  end
end
