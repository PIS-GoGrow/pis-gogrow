# frozen_string_literal: true

require "rails_helper"

# Historia IBP-048: "Como PROVEEDOR, quiero consultar y configurar los datos y
# preferencias de notificación de mi perfil para gestionar mi cuenta."
#
# Criterio 2 (configurar los tipos de notificación disponibles), criterio 3
# (persistencia) y criterio 4 (aislamiento entre proveedores) sobre
# /settings/notifications.
#
# El único canal configurable hoy es WhatsApp (las notificaciones in-app llegan
# siempre); lo que se elige son los grupos de notificación, que son los que
# expone la pantalla. No hay un selector de canal separado que testear.
RSpec.describe "Configurar las notificaciones del proveedor" do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider_user) { users(:provider_user) }
  let(:orders_title) { "Pedidos nuevos" }
  let(:payments_title) { "Comprobantes de pago" }
  let(:provider_orders) { Notification::Configuration.find_by!(key: "provider_orders") }

  def row_for(title)
    find("h2", text: title).ancestor("div.border-b")
  end

  def switch_for(title)
    row_for(title).find("button[role='switch']")
  end

  def expect_switch(title, on:)
    expect(row_for(title)).to have_css("button[role='switch'][aria-checked='#{on}']")
  end

  it "muestra sólo los grupos del proveedor, apagados al principio" do
    sign_in provider_user, role: :provider
    visit provider_account_path
    click_link "Notificaciones"

    expect(page).to have_current_path(settings_notifications_path)
    expect(page).to have_content(orders_title)
    expect(page).to have_content(payments_title)
    expect_switch(orders_title, on: false)
    expect_switch(payments_title, on: false)
    expect(page).to have_no_content("Actualizaciones de pedidos")
    expect(page).to have_no_content("Pagos a proveedores")
  end

  it "prende y apaga un grupo y lo conserva al volver a iniciar sesión" do
    sign_in provider_user, role: :provider
    visit settings_notifications_path

    switch_for(orders_title).click
    expect(page).to have_content("Configuración actualizada")
    expect_switch(orders_title, on: true)
    expect(provider_orders.reload.users).to include(provider_user)

    sign_out
    sign_in provider_user, role: :provider
    visit settings_notifications_path
    expect_switch(orders_title, on: true)

    switch_for(orders_title).click
    expect_switch(orders_title, on: false)
    expect(provider_orders.reload.users).to be_empty
  end

  it "lo que prende un proveedor no cambia lo de otro" do
    sign_in provider_user, role: :provider
    visit settings_notifications_path

    switch_for(orders_title).click
    expect(page).to have_content("Configuración actualizada")
    sign_out

    sign_in users(:other_provider_user), role: :provider
    visit settings_notifications_path
    expect_switch(orders_title, on: false)
  end

  it "a RRHH le muestra sólo sus grupos, no los del proveedor" do
    sign_in users(:admin), role: :admin
    visit settings_notifications_path

    expect(page).to have_content("Pagos a proveedores")
    expect(page).to have_no_content(orders_title)
    expect(page).to have_no_content(payments_title)
  end
end
