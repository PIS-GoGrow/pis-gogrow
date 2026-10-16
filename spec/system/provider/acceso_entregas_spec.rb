# frozen_string_literal: true

require "rails_helper"

# Defecto 86e3mhpbb: el proveedor no llegaba a "Entregas" desde Configuración.
# El recorrido se hace por la UI, sin visitar la URL de la pantalla, porque los
# specs que entraban por URL no detectaron que el enlace faltaba.
RSpec.describe "Acceso a Entregas desde la Cuenta del proveedor" do
  fixtures :users, :providers

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  def open_deliveries
    visit_hydrated provider_dashboard_path
    find("[data-sidebar=menu-button]", text: provider_user.name).click
    find("[role=menuitem]", text: "Configuración").click
    expect(page).to have_current_path(provider_account_path)
    click_on "Entregas"
    expect(page).to have_current_path(provider_deliveries_path)
    wait_for_hydration
  end

  def selected_option
    find("[role=radio][aria-checked=true]")[:id]
  end

  it "lets the provider choose office only and keeps it after signing in again" do
    sign_in provider_user, role: :provider
    open_deliveries

    expect(page).to have_content("Elegí dónde realizás tus entregas y si aceptás direcciones personalizadas.")
    expect(selected_option).to eq("delivery-home")

    find("label", text: "Solo Oficinas").click

    expect(page).to have_content("Guardamos tu modalidad de entrega")
    expect(provider.reload.home_delivery).to be(false)

    sign_out
    sign_in provider_user, role: :provider
    open_deliveries

    expect(selected_option).to eq("delivery-office")
  end

  it "goes back to the account screen with the back arrow" do
    sign_in provider_user, role: :provider
    open_deliveries

    click_on "Volver a Cuenta"

    expect(page).to have_current_path(provider_account_path)
  end
end
