# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Flujo de navegación y pantalla de inicio para roles", type: :system do
  fixtures :users, :consumers, :providers, :admins, :companies

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:admin_user) { users(:admin) }

  describe "Acceso a rutas públicas de inicio sin sesión" do
    it "muestra la pantalla de inicio para empleados en la raíz /" do
      visit root_path

      expect(page).to have_content("Viandas GoGrow")
      expect(page).to have_content("Tu almuerzo, sin complicaciones")
      expect(page).to have_button("Iniciar sesión con Google")
    end

    it "redirige /provider a /proveedor" do
      visit provider_welcome_path

      expect(page).to have_current_path(provider_sign_in_path)
    end

    it "muestra la pantalla de bienvenida de RRHH en /rrhh" do
      visit admin_welcome_path

      expect(page).to have_content("Viandas GoGrow")
      expect(page).to have_content("Simplificá las viandas de tu equipo")
      expect(page).to have_button("Continuar con Google")
    end

    it "muestra la página de no encontrado (404) al intentar ingresar a /sign_up" do
      visit "/sign_up"

      expect(page).to have_content("¡Ups! Esta página no existe")
      expect(page).to have_content("La dirección que buscás no está disponible o fue movida.")
    end
  end

  describe "Redirección automática para usuarios ya autenticados" do
    it "redirige al empleado al panel de consumidor al acceder al inicio" do
      sign_in consumer_user, role: :consumer

      visit root_path
      expect(page).to have_current_path(dashboard_path)

      visit provider_welcome_path
      expect(page).to have_current_path(dashboard_path)
    end

    it "redirige al proveedor al panel de proveedor al acceder al inicio" do
      sign_in provider_user, role: :provider

      visit root_path
      expect(page).to have_current_path(provider_dashboard_path)

      visit provider_welcome_path
      expect(page).to have_current_path(provider_dashboard_path)
    end

    it "redirige al administrador de RRHH a su panel al acceder al inicio" do
      sign_in admin_user, role: :admin

      visit root_path
      expect(page).to have_current_path(admin_dashboard_path)

      visit admin_welcome_path
      expect(page).to have_current_path(admin_dashboard_path)
    end
  end
end
