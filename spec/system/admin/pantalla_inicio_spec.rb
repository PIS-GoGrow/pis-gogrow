# frozen_string_literal: true

# Historia IBP-076: "Como RRHH, quiero visualizar una pantalla de inicio, para
# comprender qué puedo hacer con la aplicación según mi perfil." No tiene
# criterios de aceptación: se prueba el enunciado.

require "rails_helper"

RSpec.describe "Pantalla de inicio de RRHH", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers

  let(:admin_user) { users(:admin) }

  def sidebar
    find("[data-sidebar='sidebar']")
  end

  it "greets HR and shows what is coming to the home" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    expect(page).to have_content("Hola, #{admin_user.name.split.first}")
    expect(page).to have_content(I18n.l(Date.current, format: "%A %-d de %B").capitalize)
    expect(page).to have_content("Tu consumo")
    expect(page).to have_content("Tus pagos de #{I18n.l(Date.current, format: "%B").downcase}")
    expect(page).to have_content("Ranking deuda de empleados")
  end

  it "shows in the navigation what HR can use now and what is still to come" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    within(sidebar) do
      expect(page).to have_css("[data-active='true']", text: "Inicio")
      expect(page).to have_link("Beneficio general")
      expect(page).to have_link("Cuenta")

      %w[Empleados Pagos].each do |pending|
        expect(page).to have_no_link(pending)
        expect(page).to have_css("[aria-disabled='true'][title='Próximamente']", text: pending)
      end
    end
  end

  it "goes from the home to an available section and back" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    within(sidebar) { click_on "Beneficio general" }
    expect(page).to have_current_path(admin_benefit_configurations_path)

    within(sidebar) { click_on "Inicio" }
    expect(page).to have_current_path(admin_dashboard_path)
    expect(page).to have_content("Hola,")
  end

  describe "permissions" do
    it "sends a visitor to sign in" do
      visit admin_dashboard_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "keeps a consumer and a provider out of the HR home" do
      sign_in users(:one), role: :consumer
      visit admin_dashboard_path
      expect(page).to have_no_current_path(admin_dashboard_path)

      sign_out
      sign_in users(:provider_user), role: :provider
      visit admin_dashboard_path
      expect(page).to have_no_current_path(admin_dashboard_path)
    end
  end
end
