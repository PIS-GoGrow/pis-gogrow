# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::PaymentDetails", type: :request do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider) { providers(:tuviandita) }
  let(:valid_params) do
    {
      provider: {
        bank_name: "BROU",
        bank_account_details: "Cuenta: 001234567-00001\nMoneda: UYU",
        beneficiary: "Tu Vianda SRL"
      }
    }
  end

  describe "GET /provider/datos-de-cobro" do
    it "muestra los datos de cobro del proveedor" do
      provider.update!(
        bank_name: "Itaú",
        bank_account_details: "Cuenta: 123456\nMoneda: UYU",
        beneficiary: "Tu Vianda SRL"
      )
      sign_in provider.user, role: :provider

      get provider_payment_details_path

      expect(inertia).to render_component("provider/payment_details/show")
      expect(inertia).to(have_props do |props|
        props.dig("provider", "bank_name") == "Itaú" &&
          props.dig("provider", "bank_account_details") == "Cuenta: 123456\nMoneda: UYU" &&
          props.dig("provider", "beneficiary") == "Tu Vianda SRL" &&
          props["bank_names"].include?("Santander") &&
          props["bank_names"].include?("Itaú") &&
          props["editing"] == false
      end)
    end

    it "muestra el formulario si no hay datos y permite abrirlo para editar" do
      sign_in provider.user, role: :provider

      get provider_payment_details_path
      expect(inertia).to have_props(editing: true)

      provider.update!(bank_name: "BROU", bank_account_details: "Cuenta 123", beneficiary: "Tu Vianda SRL")
      get provider_payment_details_path(edit: true)
      expect(inertia).to have_props(editing: true)
    end

    it "no deja entrar a un empleado" do
      sign_in users(:one), role: :consumer

      get provider_payment_details_path

      expect(response).to redirect_to(root_path)
    end

    it "no deja entrar a RRHH" do
      sign_in users(:admin), role: :admin

      get provider_payment_details_path

      expect(response).to redirect_to(root_path)
    end

    it "pide iniciar sesión sin una sesión activa" do
      get provider_payment_details_path

      expect(response).to redirect_to(provider_sign_in_path)
    end
  end

  describe "PATCH /provider/datos-de-cobro" do
    before { sign_in provider.user, role: :provider }

    it "guarda los datos y persisten al volver a entrar" do
      patch provider_payment_details_path, params: valid_params

      expect(response).to redirect_to(provider_payment_details_path)
      follow_redirect!
      expect(inertia).to have_flash(notice: "Datos de cobro actualizados")
      expect(inertia).to have_props(editing: false)
      expect(provider.reload).to have_attributes(
        bank_name: "BROU",
        bank_account_details: "Cuenta: 001234567-00001\nMoneda: UYU",
        beneficiary: "Tu Vianda SRL"
      )
    end

    it "marca payment_details_configured_at al guardar los datos correctamente" do
      provider.update_column(:payment_details_configured_at, nil)

      expect do
        patch provider_payment_details_path, params: valid_params
      end.to change { provider.reload.payment_details_configured_at }.from(nil)
    end

    it "preserva el timestamp previo de payment_details_configured_at (idempotente)" do
      existing_timestamp = 3.days.ago.change(usec: 0)
      provider.update_column(:payment_details_configured_at, existing_timestamp)

      patch provider_payment_details_path, params: valid_params

      expect(provider.reload.payment_details_configured_at).to eq(existing_timestamp)
    end

    it "registra quién hizo el cambio y los valores anterior y nuevo" do
      patch provider_payment_details_path, params: valid_params

      log = provider.audit_logs.sole
      expect(log.user).to eq(provider.user)
      expect(log.changeset["bank_name"]).to eq([ nil, "BROU" ])
      expect(log.changeset["bank_account_details"]).to eq([ nil, "Cuenta: 001234567-00001\nMoneda: UYU" ])
    end

    it "no modifica otro proveedor" do
      patch provider_payment_details_path, params: valid_params

      expect(providers(:endulzate).reload.bank_name).to be_nil
    end

    it "exige los tres datos y mantiene el modo edición si faltan campos obligatorios" do
      provider.update_column(:payment_details_configured_at, nil)

      patch provider_payment_details_path, params: { provider: { bank_name: "BROU" } }

      expect(response).to redirect_to(provider_payment_details_path(edit: true))
      expect(provider.reload.payment_details_configured_at).to be_nil
      follow_redirect!
      expect(inertia).to(have_props do |props|
        props["editing"] == true &&
          props["errors"].keys.include?("bank_account_details") &&
          props["errors"].keys.include?("beneficiary")
      end)
      expect(provider.reload.bank_name).to be_nil
      expect(provider.audit_logs).to be_empty
    end

    it "admite texto libre y múltiples líneas en los datos de la cuenta" do
      details = "Transferencias desde otros bancos\nCuenta: UY00 0000 1150 260\nSucursal: 70 - Golf"

      patch provider_payment_details_path, params: valid_params.deep_merge(provider: { bank_account_details: details })

      expect(provider.reload.bank_account_details).to eq(details)
    end

    it "conserva los datos antiguos que ya no forman parte del formulario" do
      provider.update_columns(tax_id: "212345670012")

      patch provider_payment_details_path, params: valid_params

      expect(provider.reload).to have_attributes(tax_id: "212345670012")
    end
  end

  describe "PATCH /provider/datos-de-cobro con otro rol" do
    it "no deja que un consumidor cambie los datos ni marque timestamp" do
      provider.update_column(:payment_details_configured_at, nil)
      sign_in users(:one), role: :consumer

      patch provider_payment_details_path, params: valid_params

      expect(response).to redirect_to(root_path)
      expect(provider.reload.bank_name).to be_nil
      expect(provider.reload.payment_details_configured_at).to be_nil
    end

    it "no deja que RRHH cambie los datos ni marque timestamp" do
      provider.update_column(:payment_details_configured_at, nil)
      sign_in users(:admin), role: :admin

      patch provider_payment_details_path, params: valid_params

      expect(response).to redirect_to(root_path)
      expect(provider.reload.bank_name).to be_nil
      expect(provider.reload.payment_details_configured_at).to be_nil
    end
  end
end
