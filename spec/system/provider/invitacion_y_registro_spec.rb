# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitación y registro de proveedor", type: :system do
  fixtures :users, :companies, :providers

  let(:company) { companies(:gogrow) }
  let(:invited_name) { "Carlos Proveedor" }
  let(:invited_email) { "carlos@proveedor.com" }
  let(:strong_password) { "Nueva-Clave-2026-ok!" }

  let!(:user) do
    Providers::Invite.call(name: invited_name, email: invited_email, company: company)
  end
  let(:token) do
    "#{user.id}.#{OtpCode.find_by!(user: user, purpose: :invitation).code}"
  end

  it "permite al proveedor registrarse con contraseña segura, entrar al panel y no editar su email" do
    visit_hydrated provider_invitation_path(token: token)

    expect(page).to have_content("Regístrese con Email")
    expect(page).to have_content("Configure su contraseña para completar el registro.")

    # Criterio 2: El email no se puede editar, es al que se le mandó la invitación
    email_field = find_field("email", disabled: true)
    expect(email_field.value).to eq(invited_email)
    expect(email_field[:readonly]).to be_present

    # La contraseña debe cumplir las 4 reglas (16+ caracteres, mayúscula, número y símbolo)
    fill_in "password", with: "debil"
    fill_in "password_confirmation", with: "debil"

    # El botón de registrarse permanece deshabilitado si la contraseña no cumple la política
    expect(page).to have_button("Registrarse", disabled: true)

    # Ingresa contraseña válida de 16+ caracteres con mayúscula, número y símbolo
    fill_in "password", with: strong_password
    fill_in "password_confirmation", with: strong_password

    expect(page).to have_button("Registrarse", disabled: false)
    click_button "Registrarse"

    # Entra al onboarding del proveedor y completa los pasos para llegar al panel
    expect(page).to have_current_path(provider_onboarding_path)
    expect(page).to have_content("Paso 1 de 4")
    find("button[aria-label='Omitir por ahora']").click

    expect(page).to have_content("Paso 2 de 4")
    find("button[aria-label='Omitir por ahora']").click

    expect(page).to have_content("Paso 3 de 4")
    find("button[aria-label='Omitir por ahora']").click

    expect(page).to have_content("Paso 4 de 4")
    find("button[aria-label='Omitir por ahora']").click

    expect(page).to have_content("¡Todo listo!")
    click_on "Ir al Inicio"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(page).to have_content("Hola, #{invited_name}")

    # Cierre de sesión vuelve a /provider
    find("[data-sidebar='menu-button']", text: invited_name).click
    click_on "Cerrar sesión"

    expect(page).to have_current_path(provider_sign_in_path)
  end

  it "redirige fuera del registro si un usuario ya autenticado abre el enlace de invitación" do
    sign_in users(:one), role: :consumer

    visit provider_invitation_path(token: token)

    expect(page).to have_current_path(dashboard_path)
  end

  it "redirige al inicio de sesión del proveedor si el token es inválido" do
    visit provider_invitation_path(token: "token-invalido")

    expect(page).to have_current_path(provider_sign_in_path)
    expect(page).to have_content("La invitación no es válida o ya fue usada.")
  end
end
