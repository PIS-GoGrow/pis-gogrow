# frozen_string_literal: true

require "rails_helper"

# Historia IBP-048: "Como PROVEEDOR, quiero consultar y configurar los datos y
# preferencias de notificación de mi perfil para gestionar mi cuenta."
#
# Criterio 1 (editar email), criterio 3 (validación) y criterio 4 (auditoría)
# sobre /settings/email, a donde lleva el ítem "Correo electrónico" del sidebar de
# configuración. Cambiar el correo exige la contraseña actual.
RSpec.describe "Editar el correo del proveedor" do
  fixtures :users, :providers, :admins, :companies

  let(:provider_user) { users(:provider_user) }

  before { sign_in provider_user, role: :provider }

  it "cambia el correo con la contraseña actual y queda registrado en la auditoría" do
    visit settings_profile_path
    click_link "Correo electrónico"

    expect(page).to have_current_path(settings_email_path)

    fill_in "email", with: "nuevo-proveedor@example.com"
    fill_in "password_challenge", with: "Secret1*3*5*"
    click_on "Guardar"

    expect(page).to have_content("Tu correo electrónico fue modificado")
    expect(provider_user.reload.email).to eq("nuevo-proveedor@example.com")
    expect(provider_user.audit_logs.sole.changeset).to eq(
      "email" => [ "provider@example.com", "nuevo-proveedor@example.com" ]
    )
  end

  it "rechaza el cambio con la contraseña actual equivocada" do
    visit settings_email_path

    fill_in "email", with: "nuevo-proveedor@example.com"
    fill_in "password_challenge", with: "equivocada"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "no es válido")
    expect(provider_user.reload.email).to eq("provider@example.com")
    expect(provider_user.audit_logs).to be_empty
  end
end
