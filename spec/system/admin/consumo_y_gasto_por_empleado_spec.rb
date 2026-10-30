# frozen_string_literal: true

# Historia IBP-032, criterio 1: "Como RRHH puedo acceder a la información
# mensual relacionada con el consumo y gasto de cada empleado".

require "rails_helper"

RSpec.describe "Consumo y gasto mensual de cada empleado", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments, :benefits, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }
  let(:consumer) { consumers(:one) }
  let(:previous_month) { 1.month.ago.to_date.beginning_of_month }
  let(:previous_key) { previous_month.strftime("%Y-%m") }

  before { sign_in admin_user, role: :admin }

  it "lists each employee with the spending of the month" do
    visit admin_consumers_path

    expect(page).to have_content("Empleados")
    expect(find("[role='combobox'][aria-label='Mes de los saldos']")).to have_text("Este mes")
    expect(page).to have_content("Test User")
    expect(page).to have_content("$950,75")
    expect(page).to have_content("Other Consumer User")
    expect(page).to have_content("$150,25")
    expect(page).to have_content("Pendiente")
    expect(page).to have_content("En revisión")
  end

  it "shows a previous month's spending when the URL asks for that month" do
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous_month, amount: 2_425)

    visit admin_consumers_path(month: previous_key)

    expect(find("[role='combobox'][aria-label='Mes de los saldos']")).to have_text(I18n.l(previous_month, format: :month_name_year))
    expect(page).to have_content("Test User")
    # Los miles de cuatro cifras también se agrupan: $2.425.
    expect(page).to have_content("$2.425")
    expect(page).to have_no_content("$950,75")
  end

  it "allows changing the month in the selector and updates spending" do
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous_month, amount: 2_425)

    visit admin_consumers_path

    expect(find("[role='combobox'][aria-label='Mes de los saldos']")).to have_text("Este mes")
    expect(page).to have_content("$950,75")

    find("[role='combobox'][aria-label='Mes de los saldos']").click
    find("[role='option']", text: I18n.l(previous_month, format: :month_name_year)).click

    expect(page).to have_current_path(admin_consumers_path(month: previous_key))
    expect(find("[role='combobox'][aria-label='Mes de los saldos']")).to have_text(I18n.l(previous_month, format: :month_name_year))
    expect(page).to have_content("$2.425")
    expect(page).to have_no_content("$950,75")
  end

  it "preserves the pending filter when changing months from the selector" do
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous_month, amount: 2_425)

    visit admin_consumers_path(filter: "pending")

    expect(page).to have_css("[role='radio'][aria-checked='true']", text: "Pendientes")

    find("[role='combobox'][aria-label='Mes de los saldos']").click
    find("[role='option']", text: I18n.l(previous_month, format: :month_name_year)).click

    expect(page).to have_current_path(%r{\A/rrhh/empleados\?(?=.*month=#{previous_key})(?=.*filter=pending)})
    expect(page).to have_css("[role='radio'][aria-checked='true']", text: "Pendientes")
    expect(page).to have_content("$2.425")
  end

  it "shows the chosen month in selector when navigating from debt ranking" do
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous_month, amount: 2_425)

    visit admin_dashboard_path(month: previous_key)

    click_on "Ver empleados con saldos pendientes"

    expect(page).to have_current_path(admin_consumers_path(filter: "pending", month: previous_key))
    expect(find("[role='combobox'][aria-label='Mes de los saldos']")).to have_text(I18n.l(previous_month, format: :month_name_year))
    expect(page).to have_css("[role='radio'][aria-checked='true']", text: "Pendientes")
    expect(page).to have_content("$2.425")
  end

  it "opens an employee and shows the month's consumption" do
    visit admin_consumers_path

    click_on "Test User"

    expect(page).to have_current_path(admin_consumer_path(consumer))
    expect(page).to have_content("Detalle del empleado")
    expect(page).to have_content("Consumo")
    expect(page).to have_content("Este mes")
    expect(page).to have_content("Beneficio")
  end

  it "opens the month detail dialog from consumption history and closes it" do
    visit_hydrated admin_consumer_path(consumer)

    expect(page).to have_content("Historial de consumo")
    first("button[aria-label^='Ver el detalle de']").click

    expect(page).to have_content("Historial de consumo:")
    expect(page).to have_content("Pedidos confirmados del mes")
    expect(page).to have_button("Cerrar")

    click_button "Cerrar"

    expect(page).to have_no_content("Pedidos confirmados del mes")
  end

  # Lo que la home muestra como deuda del empleado y lo que Empleados lista para
  # el mismo mes es el mismo número.
  it "agrees with the debt ranking of the home for the same month" do
    visit admin_dashboard_path

    within(find("section[aria-labelledby='admin-debts-title']")) do
      expect(page).to have_content("Test User")
      expect(page).to have_content("$950,75")
    end

    visit admin_consumers_path
    expect(page).to have_content("$950,75")
  end

  describe "permissions" do
    it "sends a visitor to sign in" do
      sign_out
      visit admin_consumers_path

      expect(page).to have_current_path(admin_welcome_path)
    end

    it "keeps a consumer out of the employees list" do
      sign_out
      sign_in users(:one), role: :consumer
      visit admin_consumers_path

      expect(page).to have_current_path(dashboard_path)
    end
  end
end
