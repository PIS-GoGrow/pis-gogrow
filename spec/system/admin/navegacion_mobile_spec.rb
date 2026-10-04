# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navegación móvil del administrador", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }
  let(:consumer) { consumers(:one) }

  def mobile_nav
    find("nav[aria-label='Navegación de RRHH']")
  end

  def sidebar
    find("[data-sidebar='sidebar']", visible: :all)
  end

  describe "vista móvil (375x667)" do
    before do
      page.current_window.resize_to(375, 667)
      sign_in admin_user, role: :admin
      visit admin_dashboard_path
    end

    after do
      page.current_window.resize_to(1400, 1400)
    end

    it "muestra la barra inferior, oculta el sidebar y la cabecera con hamburguesa" do
      expect(page).to have_css("nav[aria-label='Navegación de RRHH']")
      expect(page).to have_no_css("[data-sidebar='trigger']", visible: true)
      expect(page).to have_no_css("[data-sidebar='sidebar']", visible: true)
    end

    it "inicia en el dashboard con 'Inicio' activo" do
      within(mobile_nav) do
        expect(page).to have_css("a[aria-current='page']", text: "Inicio")
        expect(page).to have_no_css("a[aria-current='page']", text: "Empleados")
        expect(page).to have_no_css("a[aria-current='page']", text: "Cuenta")
      end
    end

    it "navega a Empleados y mantiene el estado activo en la lista y en el detalle" do
      within(mobile_nav) { click_on "Empleados" }

      expect(page).to have_current_path(admin_consumers_path)
      within(mobile_nav) do
        expect(page).to have_css("a[aria-current='page']", text: "Empleados")
        expect(page).to have_no_css("a[aria-current='page']", text: "Inicio")
      end

      visit admin_consumer_path(consumer)
      expect(page).to have_current_path(admin_consumer_path(consumer))
      within(mobile_nav) do
        expect(page).to have_css("a[aria-current='page']", text: "Empleados")
        expect(page).to have_no_css("a[aria-current='page']", text: "Inicio")
      end
    end

    it "navega a Cuenta (/settings/profile) y mantiene el estado activo en Subsidios" do
      within(mobile_nav) { click_on "Cuenta" }

      expect(page).to have_current_path(settings_profile_path)
      within(mobile_nav) do
        expect(page).to have_css("a[aria-current='page']", text: "Cuenta")
        expect(page).to have_no_css("a[aria-current='page']", text: "Inicio")
      end

      visit admin_benefit_configurations_path
      expect(page).to have_current_path(admin_benefit_configurations_path)
      within(mobile_nav) do
        expect(page).to have_css("a[aria-current='page']", text: "Cuenta")
        expect(page).to have_no_css("a[aria-current='page']", text: "Inicio")
      end
    end

    it "en Facturas mantiene Pagos disponible pero no activo" do
      visit admin_invoices_path
      expect(page).to have_current_path(admin_invoices_path)

      within(mobile_nav) do
        expect(page).to have_link("Pagos", href: admin_payments_path)
        expect(page).to have_no_css("[aria-current='page']", text: "Pagos")
      end
    end
  end

  describe "vista de escritorio (1400x1400)" do
    before do
      page.current_window.resize_to(1400, 1400)
      sign_in admin_user, role: :admin
      visit admin_dashboard_path
    end

    it "no muestra la barra inferior y mantiene el sidebar visible y funcional" do
      expect(page).to have_no_css("nav[aria-label='Navegación de RRHH']", visible: true)
      expect(page).to have_css("[data-sidebar='sidebar']", visible: true)

      within(sidebar) do
        expect(page).to have_link("Inicio")
        expect(page).to have_link("Empleados")
        expect(page).to have_link("Beneficio general")
      end
    end
  end

  describe "control de acceso" do
    after do
      page.current_window.resize_to(1400, 1400)
    end

    it "no muestra la barra de navegación de RRHH a un usuario consumidor" do
      page.current_window.resize_to(375, 667)
      sign_in users(:one), role: :consumer
      visit root_path

      expect(page).to have_no_css("nav[aria-label='Navegación de RRHH']")
    end

    it "no muestra la barra de navegación de RRHH a un usuario proveedor" do
      page.current_window.resize_to(375, 667)
      sign_in users(:provider_user), role: :provider
      visit provider_dashboard_path

      expect(page).to have_no_css("nav[aria-label='Navegación de RRHH']")
    end
  end
end
