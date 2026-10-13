# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inicio y cierre de sesión de proveedor", type: :system do
  fixtures :users, :companies, :providers

  let(:provider_user) { users(:provider_user) }
  let(:password) { "Secret1*3*5*" }

  it "permite al proveedor iniciar sesión, navegar al panel y cerrar sesión" do
    visit_hydrated provider_sign_in_path

    expect(page).to have_content("¡Bienvenido de nuevo!")
    expect(page).to have_content("Ingrese a su cuenta para continuar gestionando sus viandas.")

    # Credenciales incorrectas
    fill_in "email", with: provider_user.email
    fill_in "password", with: "clave-incorrecta"
    click_button "Iniciar sesión"

    expect(page).to have_content("El correo electrónico o la contraseña son incorrectos")

    # Credenciales correctas
    fill_in "email", with: provider_user.email
    fill_in "password", with: password
    click_button "Iniciar sesión"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(page).to have_content("Hola, #{provider_user.name}")

    # Cierre de sesión vuelve a /provider
    find("[data-sidebar='menu-button']", text: provider_user.name).click
    click_on "Cerrar sesión"

    expect(page).to have_current_path(provider_sign_in_path)
  end

  it "muestra el diálogo de recuperación de contraseña al hacer clic en Olvidó su contraseña" do
    visit_hydrated provider_sign_in_path

    click_button "¿Olvidó su contraseña?"

    expect(page).to have_content("Ingrese su email y le enviaremos un código para restablecer su contraseña.")
    expect(page).to have_button("Enviar código")
  end
end
