# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cálculo único de viandas del cupo mensual", type: :system do
  fixtures :users, :companies, :consumers, :providers, :benefit_configurations,
           :benefit_rules, :benefits, :menus, :schedules, :admins, :accounts, :orders

  let(:consumer_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:admin_user) { users(:admin) }
  let(:provider1) { providers(:tuviandita) }
  let(:provider2) { providers(:endulzate) }
  let(:menu1) { menus(:milanesa) }
  let(:menu2) do
    Menu.create!(provider: provider2, name: "Tarta casera", description: "Con masa casera", price: 300)
  end

  before do
    Order.destroy_all
    Schedule.delete_all
  end

  it "unifies monthly benefit counts across Inicio, Pagos, Cuenta and RRHH detail" do
    schedule1 = Schedule.create!(menu: menu1, date: Date.current, amount: 20)
    schedule2 = Schedule.create!(menu: menu2, date: Date.current, amount: 20)

    # Pedido 1 con Proveedor 1: 2 viandas confirmadas con beneficio mensual
    Order.create!(
      consumer:, schedule: schedule1, amount: 2, price: 600,
      address: consumer.company.address, delivery_method: :office, status: :confirmed
    ).apply_benefit! benefits(:monthly), 2

    # Pedido 2 con Proveedor 2: 3 viandas pendientes donde solo 1 usa cupo mensual
    Order.create!(
      consumer:, schedule: schedule2, amount: 3, price: 900,
      address: consumer.company.address, delivery_method: :office, status: :pending
    ).apply_benefit! benefits(:monthly), 1

    # Pedido 3 con Proveedor 1: 4 viandas canceladas (no debe computar)
    Order.create!(
      consumer:, schedule: schedule1, amount: 4, price: 1200,
      address: consumer.company.address, delivery_method: :office, status: :cancelled
    ).apply_benefit! benefits(:monthly), 4

    # 1. Pantalla Inicio: muestra "3 de 20 viandas pedidas"
    sign_in consumer_user, role: :consumer
    visit dashboard_path

    expect(page).to have_content("3 de 20")
    expect(page).to have_content("viandas pedidas")

    # 2. Pantalla Pagos: muestra "3 de 20 viandas"
    visit accounts_path
    expect(page).to have_content("3 de 20 viandas")

    # 3. Pantalla Cuenta: muestra "17 viandas" restantes (20 - 3 = 17)
    visit profile_path
    within(find("section[aria-labelledby=benefit-title]")) do
      expect(page).to have_content("17 viandas")
    end

    # 4. Detalle del empleado en RRHH: muestra "3 de 20 viandas consumidas" y desglose por proveedor
    sign_out
    sign_in admin_user, role: :admin
    visit admin_consumer_path(consumer)

    expect(page).to have_content("3 de 20 viandas consumidas")
    expect(page).to have_content(provider1.user.name)
    expect(page).to have_content("2 viandas")
    expect(page).to have_content(provider2.user.name)
    expect(page).to have_content("1 vianda")
  end
end
