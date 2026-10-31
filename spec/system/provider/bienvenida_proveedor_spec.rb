# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bienvenida e invitación de proveedor", type: :system do
  fixtures :users, :companies, :providers

  let(:company) { companies(:gogrow) }
  let(:invited_name) { "Marta Proveedora" }
  let(:invited_email) { "marta@proveedor.com" }

  let!(:user) do
    Providers::Invite.call(name: invited_name, email: invited_email, company: company)
  end
  let(:token) do
    "#{user.id}.#{OtpCode.find_by!(user: user, purpose: :invitation).code}"
  end
  let(:company_token) do
    company.signed_id(purpose: :provider_invitation)
  end

  it "muestra la pantalla de bienvenida personalizada y permite avanzar al registro" do
    visit_hydrated provider_welcome_path(token: token, company: company_token)

    expect(page).to have_content("Bienvenido a Viandas GoGrow")
    expect(page).to have_content("¡Hola #{invited_name}! #{company.name} te invitó a unirte como proveedor de viandas.")
    expect(page).to have_css("section[aria-roledescription='carousel']")
    expect(page).to have_content("Tu menú, siempre actualizado")
    expect(page).to have_content("Todos tus pedidos bajo control")
    expect(page).to have_content("Cobros claros y ordenados")

    click_link "Unirse ahora"

    expect(page).to have_current_path(provider_invitation_path)
    expect(page).to have_content("Registrate con Email")
  end

  it "redirige al inicio de sesión de proveedor si el token está alterado" do
    visit provider_welcome_path(token: "token-invalido", company: company_token)

    expect(page).to have_current_path(provider_sign_in_path)
    expect(page).to have_content("La invitación no es válida o ya fue usada.")
  end

  it "redirige al inicio de sesión de proveedor si la firma de empresa está alterada" do
    visit provider_welcome_path(token: token, company: "firma-empresa-invalida")

    expect(page).to have_current_path(provider_sign_in_path)
    expect(page).to have_content("La invitación no es válida o ya fue usada.")
  end
end
