# frozen_string_literal: true

require "rails_helper"

# Historia IBP-048: "Como PROVEEDOR, quiero consultar y configurar los datos y
# preferencias de notificación de mi perfil para gestionar mi cuenta."
#
# Criterio 1, la mitad "consultar": /provider/cuenta es el índice del perfil del
# proveedor, a donde manda el menú de usuario ("Configuración") cuando el rol
# activo es proveedor (app/javascript/components/user-menu-content.tsx). Desde acá
# se entra a Perfil, Datos de cobro, Configuración operativa, Entregas y
# Notificaciones; los flujos de edición viven en sus propios specs.
#
# TODO(integración): falta un control para editar la foto de perfil antes de poder
# testear la parte del criterio 1 que pide "editar ... foto". Hoy avatar_url sólo se
# completa desde Google (User.find_or_create_from_google) y los proveedores entran
# con email y contraseña, no con Google, así que ninguna pantalla permite cambiarla:
# lo único observable es el respaldo con iniciales. Historia IBP-048, criterio 1.
RSpec.describe "Consultar la cuenta del proveedor" do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider_user) { users(:provider_user) }

  it "muestra la identidad del proveedor y cada sección de configuración" do
    sign_in provider_user, role: :provider
    visit provider_account_path

    expect(page).to have_content("Provider User")
    expect(page).to have_content("provider@example.com")
    expect(page).to have_link("Perfil", href: settings_profile_path)
    expect(page).to have_link("Datos de cobro", href: provider_payment_details_path)
    expect(page).to have_link("Configuración operativa", href: provider_operational_settings_path)
    expect(page).to have_link("Entregas", href: provider_deliveries_path)
    expect(page).to have_link("Notificaciones", href: settings_notifications_path)
  end

  it "entra a los datos de cobro desde la cuenta" do
    sign_in provider_user, role: :provider
    visit provider_account_path

    click_link "Datos de cobro"

    expect(page).to have_current_path(provider_payment_details_path)
    expect(page).to have_content("Indicá la cuenta donde querés recibir los pagos")
  end

  it "no deja entrar a un consumidor ni a RRHH" do
    sign_in users(:one), role: :consumer
    visit provider_account_path
    expect(page).to have_no_current_path(provider_account_path)

    sign_out
    sign_in users(:admin), role: :admin
    visit provider_account_path
    expect(page).to have_no_current_path(provider_account_path)
  end

  it "no deja entrar sin sesión" do
    visit provider_account_path

    expect(page).to have_current_path(provider_sign_in_path)
    expect(page).to have_no_content("Datos de cobro")
  end
end
