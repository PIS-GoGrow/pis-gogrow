# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consumer Payments and Bank Details", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts, :admins, :payments

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:admin_user) { users(:admin) }
  let(:provider_with_bank) { providers(:tuviandita) }
  let(:provider_without_bank) { providers(:office_provider) }

  describe "Visualización de datos bancarios de los proveedores" do
    before do
      provider_with_bank.update!(
        bank_name: "Banco Itaú",
        bank_account_number: "1951234",
        bank_account_holder: "Tu Vianda SRL"
      )
      provider_without_bank.update!(
        bank_name: nil,
        bank_account_number: nil,
        bank_account_holder: nil
      )
      sign_in consumer_user, role: :consumer
    end

    it "muestra la tarjeta de datos bancarios completos con banco, cuenta, beneficiario y botón de copia" do
      visit accounts_path

      card = find("[data-slot='card-title']", text: provider_with_bank.user.name, exact_text: true).ancestor("[data-slot='card']")

      within(card) do
        expect(page).to have_content("Banco Itaú")
        expect(page).to have_content("Nº de cuenta: 1951234")
        expect(page).to have_content("Beneficiario: Tu Vianda SRL")
        expect(page).to have_button("Copiar número de cuenta")
      end
    end

    it "muestra el mensaje de fallback cuando el proveedor no cargó sus datos de cobro" do
      visit accounts_path

      card = find("[data-slot='card-title']", text: provider_without_bank.user.name, exact_text: true).ancestor("[data-slot='card']")

      within(card) do
        expect(page).to have_content("Este proveedor todavía no cargó sus datos de cobro.")
        expect(page).not_to have_content("Nº de cuenta:")
        expect(page).not_to have_content("Beneficiario:")
        expect(page).not_to have_button("Copiar número de cuenta")
      end
    end
  end

  describe "Orden de períodos de cuentas pendientes y consistencia de estados" do
    let(:older_month) { 2.months.ago.to_date.beginning_of_month }
    let(:current_month) { Date.current.beginning_of_month }

    before do
      Account.create!(
        owner: consumer_user.consumer,
        provider: provider_with_bank,
        month: older_month,
        amount: 250
      )
    end

    it "muestra los períodos desde el más reciente al más antiguo dentro de la tarjeta del proveedor" do
      sign_in consumer_user, role: :consumer
      visit accounts_path

      card = find("[data-slot='card-title']", text: provider_with_bank.user.name, exact_text: true).ancestor("[data-slot='card']")

      within(card) do
        current_period_label = I18n.l(current_month, format: :month_year)
        older_period_label = I18n.l(older_month, format: :month_year)

        expect(page).to have_content(current_period_label)
        expect(page).to have_content(older_period_label)

        expect(page.text.index(current_period_label)).to be < page.text.index(older_period_label)
      end
    end

    it "muestra el estado 'En revisión' en la tarjeta cuando el pago fue enviado con comprobante" do
      payment = payments(:other_submitted)
      payment.receipt.attach(
        io: StringIO.new(File.binread(Rails.root.join("public/icon.png"))),
        filename: "comprobante.png",
        content_type: "image/png"
      )

      sign_in users(:other_consumer_user), role: :consumer
      visit accounts_path

      card = find("[data-slot='card-title']", text: provider_with_bank.user.name, exact_text: true).ancestor("[data-slot='card']")

      within(card) do
        expect(page).to have_content("En revisión")
      end
    end
  end

  describe "Control de accesos y seguridad a nivel de navegador" do
    it "permite el acceso al empleado consumidor a la pantalla de pagos" do
      sign_in consumer_user, role: :consumer
      visit accounts_path

      expect(page).to have_current_path(accounts_path)
      expect(page).to have_content("Pagos")
    end

    it "bloquea el acceso a usuarios con rol proveedor redirigiendo con mensaje de alerta" do
      sign_in provider_user, role: :provider
      visit accounts_path

      expect(page).to have_no_current_path(accounts_path)
      expect(page).to have_content("No tenés permiso para acceder a este recurso.")
    end

    it "bloquea el acceso a usuarios con rol admin redirigiendo con mensaje de alerta" do
      sign_in admin_user, role: :admin
      visit accounts_path

      expect(page).to have_no_current_path(accounts_path)
      expect(page).to have_content("No tenés permiso para acceder a este recurso.")
    end

    it "redirige a usuarios no autenticados solicitando inicio de sesión" do
      visit accounts_path

      expect(page).to have_no_current_path(accounts_path)
      expect(page).to have_content("Tenés que iniciar sesión para acceder a este recurso.")
    end
  end
end
