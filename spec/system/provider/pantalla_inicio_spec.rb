# frozen_string_literal: true

# Historia IBP-077: "Como proveedor, quiero visualizar una pantalla de inicio,
# para tener un resumen de la operación diaria, hallazgos y cobros."

require "rails_helper"

RSpec.describe "Pantalla de inicio del proveedor", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :reviews, :accounts, :order_accounts, :payments

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  def sidebar
    find("[data-sidebar='sidebar']", visible: :all)
  end

  def mobile_nav
    find("nav[aria-label='Navegación del proveedor']")
  end

  describe "vista de escritorio" do
    before do
      page.current_window.resize_to(1400, 1400)
      sign_in provider_user, role: :provider
      visit provider_dashboard_path
    end

    it "muestra el saludo, la fecha del día y las secciones de resumen" do
      expect(page).to have_content("Hola, #{provider_user.name}")
      expect(page).to have_content(I18n.l(Date.current, format: "%A, %-d de %B").capitalize)

      expect(page).to have_content("Pedidos")
      expect(page).to have_content("Confirmados")
      expect(page).to have_content("Pendientes")
      expect(page).to have_content("Envío a oficina")
      expect(page).to have_content("Envío a domicilio")

      expect(page).to have_content("Hallazgos del mes")
      expect(page).to have_content("Resumen de cobros")
    end

    it "permite navegar a pedidos y regresar al inicio mediante la barra lateral" do
      within(sidebar) do
        expect(page).to have_link("Inicio")
        expect(page).to have_link("Menús")
        expect(page).to have_link("Pedidos")
        expect(page).to have_link("Cobros")

        click_on "Pedidos"
      end

      expect(page).to have_current_path(provider_orders_path)

      within(sidebar) { click_on "Inicio" }
      expect(page).to have_current_path(provider_dashboard_path)
    end

    it "permite navegar a pedidos desde la tarjeta de resumen" do
      click_on "Ver pedidos"

      expect(page).to have_current_path(provider_orders_path)
    end
  end

  describe "vista móvil" do
    before do
      page.current_window.resize_to(375, 667)
      sign_in provider_user, role: :provider
      visit provider_dashboard_path
    end

    after do
      page.current_window.resize_to(1400, 1400)
    end

    it "muestra la barra de navegación inferior con accesos disponibles" do
      expect(page).to have_css("nav[aria-label='Navegación del proveedor']")

      within(mobile_nav) do
        expect(page).to have_link("Inicio")
        expect(page).to have_link("Menú")
        expect(page).to have_link("Pedidos")
        expect(page).to have_link("Cobros")
        expect(page).to have_link("Cuenta")

        click_on "Pedidos"
      end

      expect(page).to have_current_path(provider_orders_path)
    end
  end

  describe "control de acceso" do
    it "redirige al visitante no autenticado a iniciar sesión" do
      visit provider_dashboard_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "no permite el acceso a usuarios con rol consumidor" do
      sign_in users(:one), role: :consumer
      visit provider_dashboard_path

      expect(page).to have_no_current_path(provider_dashboard_path)
    end
  end
end
