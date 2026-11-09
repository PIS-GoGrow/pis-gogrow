# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::PaymentDetails", type: :request do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider) { providers(:tuviandita) }
  let(:valid_params) do
    {
      provider: {
        bank_name: "BROU",
        bank_account_type: "savings",
        bank_account_number: "001234567-00001",
        bank_account_holder: "Tu Vianda SRL",
        tax_id: "21 234567 0012"
      }
    }
  end

  describe "GET /provider/datos-de-cobro" do
    it "muestra los datos de cobro del proveedor" do
      provider.update!(bank_name: "Itaú", bank_account_type: :checking)
      sign_in provider.user, role: :provider

      get provider_payment_details_path

      expect(inertia).to render_component("provider/payment_details/show")
      expect(inertia).to have_props { |props| props["provider"]["bank_name"] == "Itaú" && props["provider"]["bank_account_type"] == "checking" }
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
      expect(inertia).to have_props { |props| props["provider"]["tax_id"] == "212345670012" }
      expect(provider.reload).to have_attributes(bank_name: "BROU", bank_account_type: "savings", bank_account_holder: "Tu Vianda SRL")
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
      expect(log.changeset["tax_id"]).to eq([ nil, "212345670012" ])
    end

    it "no modifica otro proveedor" do
      patch provider_payment_details_path, params: valid_params

      expect(providers(:endulzate).reload.bank_name).to be_nil
    end

    it "exige todos los datos y no marca el timestamp si faltan campos obligatorios" do
      provider.update_column(:payment_details_configured_at, nil)

      patch provider_payment_details_path, params: { provider: { bank_name: "BROU" } }

      expect(response).to redirect_to(provider_payment_details_path)
      expect(provider.reload.payment_details_configured_at).to be_nil
      follow_redirect!
      expect(inertia.props[:errors].keys).to include("bank_account_type", "bank_account_number", "bank_account_holder", "tax_id")
      expect(provider.reload.bank_name).to be_nil
      expect(provider.audit_logs).to be_empty
    end

    it "rechaza un RUT o CI con una cantidad de dígitos inválida sin marcar timestamp" do
      provider.update_column(:payment_details_configured_at, nil)

      patch provider_payment_details_path, params: valid_params.deep_merge(provider: { tax_id: "12345" })

      expect(response).to redirect_to(provider_payment_details_path)
      expect(provider.reload.payment_details_configured_at).to be_nil
      follow_redirect!
      expect(inertia.props[:errors]).to include("tax_id" => [ "no es válido" ])
    end

    it "rechaza un tipo de cuenta que no existe sin dar error de servidor" do
      patch provider_payment_details_path, params: valid_params.deep_merge(provider: { bank_account_type: "crypto" })

      follow_redirect!
      expect(inertia.props[:errors]).to include("bank_account_type")
      expect(provider.reload.bank_account_type).to be_nil
    end

    it "rechaza un número de cuenta con letras" do
      patch provider_payment_details_path, params: valid_params.deep_merge(provider: { bank_account_number: "ABC123" })

      follow_redirect!
      expect(inertia.props[:errors]).to include("bank_account_number")
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
