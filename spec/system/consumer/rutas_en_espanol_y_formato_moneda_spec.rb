# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rutas en español y formato de moneda unificado", type: :system do
  fixtures :users, :consumers, :providers, :admins, :companies, :menus, :schedules,
           :orders, :accounts, :order_accounts, :benefits, :benefit_configurations

  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }

  describe "Navegación en el frontend con rutas en español y moneda formateada" do
    it "empleado navega a /menu-semanal y visualiza voseo y moneda formateada con signo peso" do
      sign_in consumer_user, role: :consumer
      visit dashboard_path

      expect(page).to have_current_path("/menu-semanal")
      expect(page).to have_content("Menú semanal")
      expect(page).to have_content("Tu consumo")
      expect(page).to have_content(/\$\d+/)
    end

    it "RRHH navega a /rrhh/pagos y visualiza la pantalla con importes formateados" do
      sign_in admin_user, role: :admin
      visit admin_payments_path

      expect(page).to have_current_path("/rrhh/pagos")
      expect(page).to have_content("Pagos")
      expect(page).to have_content("Deuda total")
      expect(page).to have_content("$601")
    end
  end
end
