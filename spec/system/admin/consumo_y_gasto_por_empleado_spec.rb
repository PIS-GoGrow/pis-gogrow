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
    expect(page).to have_content("Test User")
    expect(page).to have_content("950,75 UYU")
    expect(page).to have_content("Other Consumer User")
    expect(page).to have_content("150,25 UYU")
    expect(page).to have_content("Pendiente")
    expect(page).to have_content("En revisión")
  end

  it "shows a previous month's spending when the URL asks for that month" do
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous_month, amount: 2_425)

    visit admin_consumers_path(month: previous_key)

    expect(page).to have_content("Test User")
    # El locale "es" no agrupa los miles de cuatro cifras: 2425,00 UYU.
    expect(page).to have_content("2425,00 UYU")
    expect(page).to have_no_content("950,75 UYU")
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

  # Lo que la home muestra como deuda del empleado y lo que Empleados lista para
  # el mismo mes es el mismo número.
  it "agrees with the debt ranking of the home for the same month" do
    visit admin_dashboard_path

    within(find("section[aria-labelledby='admin-debts-title']")) do
      expect(page).to have_content("Test User")
      expect(page).to have_content("$950,75")
    end

    visit admin_consumers_path
    expect(page).to have_content("950,75 UYU")
  end

  describe "permissions" do
    it "sends a visitor to sign in" do
      sign_out
      visit admin_consumers_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "keeps a consumer out of the employees list" do
      sign_out
      sign_in users(:one), role: :consumer
      visit admin_consumers_path

      expect(page).to have_current_path(dashboard_path)
    end
  end
end
