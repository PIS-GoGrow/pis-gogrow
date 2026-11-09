# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Banner 'Complete su cuenta' en el panel del proveedor" do
  fixtures :users, :providers, :companies, :consumers, :admins

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }

  describe "visualización y navegación del banner" do
    it "muestra el banner con el progreso dinámico y redirige a la cuenta al hacer clic cuando la cuenta está incompleta" do
      provider.update_columns(
        payment_details_configured_at: Time.current,
        order_deadline_configured_at: Time.current,
        deliveries_configured_at: nil,
        notifications_configured_at: nil
      )

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_content("Complete su cuenta")
      expect(page).to have_content("Deje todo listo para empezar a recibir pedidos.")
      expect(page).to have_content("2/4")

      click_on "Complete su cuenta"

      expect(page).to have_current_path(provider_account_path)
    end

    it "no muestra el banner en el panel cuando todas las secciones están completadas (4/4)" do
      provider.update_columns(
        payment_details_configured_at: Time.current,
        order_deadline_configured_at: Time.current,
        deliveries_configured_at: Time.current,
        notifications_configured_at: Time.current
      )

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_no_content("Complete su cuenta")
      expect(page).to have_no_content("Deje todo listo para empezar a recibir pedidos.")
    end
  end
end
