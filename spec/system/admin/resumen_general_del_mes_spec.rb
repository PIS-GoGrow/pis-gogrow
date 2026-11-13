# frozen_string_literal: true

# Historia IBP-032: "Como RR.HH., quiero consultar un resumen general del mes
# con información del beneficio, participación, consumos, gasto y presupuesto
# para conocer el estado global del programa."
# Criterio 1: "Como RRHH puedo acceder a la información mensual relacionada con
# el consumo y gasto de cada empleado".

require "rails_helper"

RSpec.describe "Resumen general del mes de RRHH", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }
  let(:previous_month) { 1.month.ago.to_date.beginning_of_month }
  let(:previous_key) { previous_month.strftime("%Y-%m") }

  before { sign_in admin_user, role: :admin }

  def benefit_card
    find("[data-slot='card']", text: "Tu beneficio")
  end

  it "shows the benefit, participation and spending of the current month" do
    visit admin_dashboard_path

    within("nav[aria-label='breadcrumb']") do
      expect(page).to have_content("Inicio")
    end
    expect(page).to have_content("Hola, #{admin_user.name.split.first}")
    expect(page).to have_content("Tu beneficio")
    expect(page).to have_content("1 de 40")
    expect(page).to have_content("viandas pedidas")
    expect(page).to have_content("Participación")
    expect(page).to have_content("50%")
    expect(page).to have_content("Gasto")
    expect(page).to have_content("$601")

    within(benefit_card) do
      expect(page).to have_no_content(/Pagado/)
      expect(page).to have_no_content(/Pendiente/)
      expect(page).to have_no_content(/Proyectado/)
      expect(page).to have_no_link("Ver análisis del beneficio")
    end
  end

  it "summarizes the month HR picks in the selector" do
    visit admin_dashboard_path

    pick_month(previous_month)

    expect(page).to have_current_path(admin_dashboard_path(month: previous_key))
    # El mes anterior sólo tiene el subsidio de 900 ya aprobado y ninguna vianda.
    expect(page).to have_content("$900")
    expect(page).to have_content("0%")
    expect(page).to have_no_content("1 de 40")
    within(benefit_card) do
      expect(page).to have_no_content(/Pagado|Pendiente|Proyectado/)
    end
  end

  it "opens the consumption detail of the month it is showing over the home" do
    visit admin_dashboard_path

    click_on "Ver detalle del consumo"

    within(:css, "[role='dialog']") do
      expect(page).to have_content("Provider User: Consumo #{I18n.l(Date.current, format: :month_name_year).upcase_first}")
    end
    expect(page).to have_current_path(admin_dashboard_path)

    click_on "Cerrar"
    expect(page).to have_no_selector("[role='dialog']")
    pick_month(previous_month)
    expect(page).to have_current_path(admin_dashboard_path(month: previous_key))
    click_on "Ver detalle del consumo"

    within(:css, "[role='dialog']") do
      expect(page).to have_content("Provider User: Consumo #{I18n.l(previous_month, format: :month_name_year).upcase_first}")
    end
    expect(page).to have_current_path(admin_dashboard_path(month: previous_key))
  end

  # El resumen es de la empresa del admin: la cuenta de otra empresa no cambia
  # los totales.
  it "ignores another company's consumption in the month summary" do
    other_company = Company.create!(name: "Otra empresa", address: "Rivera 2000")
    Account.create!(owner: other_company, provider: providers(:tuviandita), month: Date.current, amount: 9_999)

    visit admin_dashboard_path

    expect(page).to have_content("$601")
    expect(page).to have_no_content("$9.999")
  end

  it "keeps showing the month summary after a reload and after signing in again" do
    visit admin_dashboard_path
    expect(page).to have_content("1 de 40")

    refresh
    expect(page).to have_content("1 de 40")

    sign_out
    sign_in admin_user, role: :admin
    visit admin_dashboard_path
    expect(page).to have_content("1 de 40")
  end

  it "shows Uso del beneficio in the top bar" do
    visit admin_benefit_usage_analysis_path

    within("nav[aria-label='breadcrumb']") do
      expect(page).to have_content("Uso del beneficio")
    end
  end

  it "keeps the analysis link only on mobile and opens Uso del beneficio" do
    page.current_window.resize_to(390, 844)

    visit admin_dashboard_path

    within(benefit_card) do
      expect(page).to have_no_content(/Pagado|Pendiente|Proyectado/)
      expect(page).to have_link("Ver análisis del beneficio")
    end

    click_link "Ver análisis del beneficio"

    expect(page).to have_current_path(
      admin_benefit_usage_analysis_path,
      ignore_query: true
    )
    expect(page).to have_content("Uso del beneficio")
  end

  def pick_month(date)
    find("[role='combobox'][aria-label='Mes del resumen']").click
    find("[role='option']", text: I18n.l(date, format: :month_name_year)).click
  end
end
