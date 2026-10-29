# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manejo de recursos inexistentes y pantalla 404 en el panel del proveedor", type: :system do
  fixtures :users, :providers, :menus, :schedules, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:other_menu) { menus(:sorrentinos) }

  context "cuando el proveedor está autenticado" do
    before do
      sign_in provider_user, role: :provider
    end

    it "muestra la pantalla 404 propia de GoGrow al acceder a un plato inexistente y permite volver al panel" do
      visit "/proveedor/platos/999999/editar"

      expect(page).to have_content("¡Ups! Esta página no existe")
      expect(page).to have_content("La dirección que buscás no está disponible o fue movida.")
      expect(page).not_to have_content("ActiveRecord::RecordNotFound")

      expect(page).to have_link("Ir a mi panel")
      expect(page).to have_link("Volver al inicio")

      click_link "Ir a mi panel"
      expect(page).to have_current_path(provider_dashboard_path)
    end

    it "muestra la pantalla 404 propia de GoGrow al acceder a un plato de otro proveedor" do
      visit edit_provider_menu_path(other_menu)

      expect(page).to have_content("¡Ups! Esta página no existe")
      expect(page).to have_content("La dirección que buscás no está disponible o fue movida.")
      expect(page).not_to have_content("ActiveRecord::RecordNotFound")

      click_link "Volver al inicio"
      expect(page).to have_current_path(provider_dashboard_path)
    end
  end

  context "cuando el usuario no está autenticado e intenta acceder a una ruta inexistente de proveedor" do
    it "muestra la pantalla 404 propia con enlaces para iniciar sesión como proveedor" do
      visit "/proveedor/ruta-totalmente-inexistente"

      expect(page).to have_content("¡Ups! Esta página no existe")
      expect(page).to have_link("Iniciar sesión", href: provider_sign_in_path)
      expect(page).to have_link("Volver al inicio", href: provider_sign_in_path)

      click_link "Iniciar sesión"
      expect(page).to have_current_path(provider_sign_in_path)
    end
  end
end
