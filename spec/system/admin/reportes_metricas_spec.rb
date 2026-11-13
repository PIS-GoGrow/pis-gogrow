# frozen_string_literal: true

# Historia IBP-043: "Como RR. HH., quiero consultar reportes y métricas sobre
# uso del beneficio, pedidos y pagos."
# Criterios:
# 1. RR.HH. puede seleccionar un período o rango de fechas.
# 2. RR.HH. puede visualizar porcentaje de adhesión al beneficio, volumen total
#    de pedidos, desglose de consumo por proveedor y gasto acumulado.
# 3. Los indicadores y totales se calculan únicamente a partir de pedidos reales
#    confirmados/completados y coinciden con ellos.
# 4. Si no existe actividad en el período seleccionado, la interfaz muestra
#    valores en cero o un estado vacío comprensible sin generar errores.

require "rails_helper"

RSpec.describe "Reportes y métricas de RRHH", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules, :orders

  let(:admin_user) { users(:admin) }

  before do
    # Orden confirmada en el mes anterior para extender el límite mínimo y habilitar "Mes pasado"
    prev_date = Date.current.prev_month.beginning_of_month + 10.days
    Order.create!(
      consumer: consumers(:one),
      schedule: Schedule.find_or_create_by!(menu: menus(:milanesa), date: prev_date),
      delivery_date: prev_date,
      status: :confirmed,
      delivery_method: :office,
      amount: 1,
      price: 300.5,
      discounted_price: 150.25
    )
    sign_in admin_user, role: :admin
  end

  it "permite a RR. HH. navegar a reportes y consultar los indicadores del período actual" do
    visit_hydrated admin_dashboard_path

    # Entrada desde el inicio
    click_link "Ver reportes"
    expect(page).to have_current_path(admin_reports_path)
    expect(page).to have_content("Reportes")

    # CA2 y CA3: Adhesión, pedidos, gasto acumulado y desglose por proveedor
    # Solo los pedidos confirmed del mes actual cuentan (3 confirmados, 4 viandas, 2 de 2 empleados)
    within("main") do
      expect(page).to have_content("Adhesión")
      expect(page).to have_content("100%")
      expect(page).to have_content("2 de 2 empleados")

      expect(page).to have_content("Pedidos")
      expect(page).to have_content("3")
      expect(page).to have_content("4 viandas")

      expect(page).to have_content("Gasto acumulado")
      expect(page).to have_content("$601")
      expect(page).to have_content("Empleado: $601")

      expect(page).to have_content("Consumo por proveedor")
      expect(page).to have_content("Provider User")
      expect(page).to have_content("4 viandas")
    end

    # CA1: Selección de período con preset ("Mes pasado")
    click_button "Período"
    click_button "Mes pasado"

    expect(page).to have_current_path(%r{/rrhh/reportes\?desde=\d{4}-\d{2}-\d{2}&hasta=\d{4}-\d{2}-\d{2}})
    within("main") do
      expect(page).to have_content("50%")
      expect(page).to have_content("1 de 2 empleados")
      expect(page).to have_content("1 vianda")
    end

    # CA4: Período sin actividad ("Ayer") muestra ceros y estado vacío sin errores
    click_button "Período"
    click_button "Ayer"

    expect(page).to have_current_path(%r{/rrhh/reportes\?desde=\d{4}-\d{2}-\d{2}&hasta=\d{4}-\d{2}-\d{2}})
    within("main") do
      expect(page).to have_content("0%")
      expect(page).to have_content("0 de 2 empleados")
      expect(page).to have_content("0 viandas")
      expect(page).to have_content("Sin consumos")
      expect(page).to have_content("No hay pedidos confirmados en este período.")
    end

    # Volver al inicio
    find("a[aria-label='Volver al inicio']").click
    expect(page).to have_current_path(admin_dashboard_path)
  end

  it "ofrece el enlace a Reportes en el menú de navegación de RR. HH." do
    visit_hydrated admin_dashboard_path

    within("[data-sidebar='sidebar']") do
      click_link "Reportes"
    end

    expect(page).to have_current_path(admin_reports_path)
    expect(page).to have_content("Reportes")
  end
end
