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

      expect(inertia).to(have_props do |props|
        props["step"] == "4" && props["notification_configurations"].any?
      end)
    end

    it "muestra el cierre cuando ya está completo" do
      provider.update!(onboarding_completed_at: Time.current)

      get provider_onboarding_path(step: 1)

      expect(inertia).to have_props { |props| props["step"] == "done" }
    end

    it "entrega las props exactas esperadas por el serializer" do
      get provider_onboarding_path

      expect(inertia).to(have_props do |props|
        p = props["provider"]
        p.key?("bank_name") &&
          p.key?("bank_account_type") &&
          p.key?("bank_account_number") &&
          p.key?("bank_account_holder") &&
          p.key?("tax_id") &&
          p.key?("home_delivery") &&
          p.key?("order_deadline") &&
          props["notification_configurations"].is_a?(Array) &&
          props["subscribed_keys"].is_a?(Array)
      end)
    end

    it "hace fallback al paso 1 si se pasa un parámetro de paso inválido" do
      get provider_onboarding_path(step: 99)
      expect(inertia).to have_props { |props| props["step"] == "1" }

      get provider_onboarding_path(step: "invalido")
      expect(inertia).to have_props { |props| props["step"] == "1" }
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

    it "rechaza un RUT o CI con longitud inválida en el paso 1" do
      patch provider_onboarding_path, params: { step: 1, commit: "continue", provider: payment_params.merge(tax_id: "12345") }

      expect(response).to redirect_to(provider_onboarding_path(step: 1))
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:tax_id)
    end

    it "rechaza un número de cuenta bancaria con formato inválido en el paso 1" do
      patch provider_onboarding_path, params: { step: 1, commit: "continue", provider: payment_params.merge(bank_account_number: "ABC") }

      expect(response).to redirect_to(provider_onboarding_path(step: 1))
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:bank_account_number)
    end

    it "normaliza el tax_id removiendo caracteres no numéricos al persistir" do
      patch provider_onboarding_path, params: { step: 1, commit: "continue", provider: payment_params.merge(tax_id: "21.234.567/0012") }

      expect(response).to redirect_to(provider_onboarding_path(step: 2))
      expect(provider.reload.tax_id).to eq("212345670012")
    end

    it "rechaza horas de cierre con formato inválido en el paso 2" do
      patch provider_onboarding_path, params: { step: 2, commit: "continue", order_deadline: "25:00" }

      expect(response).to redirect_to(provider_onboarding_path(step: 2))
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:order_deadline)
      expect(provider.reload.order_deadline).to be_nil
    end

    it "permite dejar la hora de cierre en blanco y avanzar en el paso 2" do
      patch provider_onboarding_path, params: { step: 2, commit: "continue", order_deadline: "" }

      expect(response).to redirect_to(provider_onboarding_path(step: 3))
    end

    it "castea valores no booleanos en entregas de forma segura en el paso 3" do
      patch provider_onboarding_path, params: { step: 3, commit: "continue", home_delivery: "cualquier_cosa" }

      expect(response).to redirect_to(provider_onboarding_path(step: 4))
    end

    it "ignora IDs de notificación inexistentes o negativos en el paso 4 sin fallar" do
      patch provider_onboarding_path, params: { step: 4, commit: "continue", subscribed_ids: [ -1, 999_999 ] }

      expect(response).to redirect_to(provider_onboarding_path(step: "done"))
      expect(provider.reload.onboarding_completed_at).to be_present
    end
  end

  describe "control de acceso por rol" do
    it "redirige al login de proveedor cuando no hay sesión activa" do
      get provider_onboarding_path
      expect(response).to redirect_to(provider_sign_in_path)

      patch provider_onboarding_path, params: { step: 1 }
      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "rechaza el acceso a un consumidor" do
      sign_in users(:one), role: :consumer

      get provider_onboarding_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it "rechaza el acceso a un administrador" do
      sign_in users(:admin), role: :admin

      get provider_onboarding_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "reflejo de la configuración del onboarding en la cuenta del proveedor" do
    before { sign_in provider.user, role: :provider }

    it "aplica los datos de cobro, hora de cierre, entregas y notificaciones en sus respectivas pantallas de configuración" do
      config = Notification::Configuration.where(configurable: true).for_role(:provider).first

      # 1. Paso 1: Datos de cobro
      patch provider_onboarding_path, params: {
        step: 1,
        commit: "continue",
        provider: {
          bank_name: "Santander",
          bank_account_type: "checking",
          bank_account_number: "987654321",
          bank_account_holder: "Tu Vianda Gastronomía",
          tax_id: "21 987654 0019"
        }
      }
      expect(response).to redirect_to(provider_onboarding_path(step: 2))

      # 2. Paso 2: Hora de cierre
      patch provider_onboarding_path, params: {
        step: 2,
        commit: "continue",
        order_deadline: "14:45"
      }
      expect(response).to redirect_to(provider_onboarding_path(step: 3))

      # 3. Paso 3: Entregas (deshabilitar entrega a domicilio)
      patch provider_onboarding_path, params: {
        step: 3,
        commit: "continue",
        home_delivery: false
      }
      expect(response).to redirect_to(provider_onboarding_path(step: 4))

      # 4. Paso 4: Notificaciones
      patch provider_onboarding_path, params: {
        step: 4,
        commit: "continue",
        subscribed_ids: config ? [ config.id ] : []
      }
      expect(response).to redirect_to(provider_onboarding_path(step: "done"))
      expect(provider.reload).to be_onboarded

      # A. Pantalla de datos de cobro (/provider/payment_details)
      get provider_payment_details_path
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("provider/payment_details/show")
      expect(inertia).to(have_props do |props|
        expect(props.dig("provider", "bank_name")).to eq("Santander")
        expect(props.dig("provider", "bank_account_type")).to eq("checking")
        expect(props.dig("provider", "bank_account_number")).to eq("987654321")
        expect(props.dig("provider", "bank_account_holder")).to eq("Tu Vianda Gastronomía")
        expect(props.dig("provider", "tax_id")).to eq("219876540019")
      end)

      # B. Pantalla de configuración operativa (/provider/operational_settings)
      get provider_operational_settings_path
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("provider/operational_settings/show")
      expect(inertia).to(have_props do |props|
        expect(props.dig(:provider, :order_deadline)).to eq("14:45")
      end)

      # C. Pantalla de entregas (/provider/deliveries)
      get provider_deliveries_path
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("provider/deliveries/show")
      expect(inertia).to(have_props do |props|
        expect(props.dig("provider", "home_delivery")).to be(false)
      end)

      # D. Pantalla de notificaciones (/settings/notifications)
      if config
        get settings_notifications_path
        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("settings/notifications/index")
        expect(inertia).to(have_props do |props|
          expect(props[:subscribed_keys]).to include(config.key)
        end)
      end
    end

    it "mantiene el estado por defecto o vacío en la configuración cuando los pasos se omiten" do
      provider.update!(bank_name: nil, tax_id: nil, order_deadline: nil, home_delivery: true)

      patch provider_onboarding_path, params: { step: 1, commit: "skip" }
      patch provider_onboarding_path, params: { step: 2, commit: "skip" }
      patch provider_onboarding_path, params: { step: 3, commit: "skip" }
      patch provider_onboarding_path, params: { step: 4, commit: "skip" }

      expect(response).to redirect_to(provider_onboarding_path(step: "done"))
      expect(provider.reload).to be_onboarded

      # Datos de cobro quedan sin configurar
      get provider_payment_details_path
      expect(inertia).to(have_props do |props|
        expect(props.dig("provider", "bank_name")).to be_nil
        expect(props.dig("provider", "tax_id")).to be_nil
      end)

      # Hora de cierre queda sin configurar
      get provider_operational_settings_path
      expect(inertia).to(have_props do |props|
        expect(props.dig(:provider, :order_deadline)).to be_nil
      end)

      # Entregas mantiene el valor default
      get provider_deliveries_path
      expect(inertia).to(have_props do |props|
        expect(props.dig("provider", "home_delivery")).to be(true)
      end)
    end
  end
end
