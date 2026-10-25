# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Asignar un cupón a empleados", type: :system do
  fixtures :users, :companies, :admins, :consumers, :providers, :benefit_configurations, :benefit_rules, :benefits

  let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan", description: "Con papas", price: 300) }

  around do |example|
    # El navegador no ve travel_to: el calendario abre en el mes real.
    @real_today = Date.current
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    # Los fixtures gift y seniority son subsidios especiales sin nombre.
    benefit_configurations(:gift, :seniority).each(&:destroy)
    benefits(:monthly).update!(percentage: 50, amount: 20, due_date: Date.current.end_of_month, status: :current)
    Schedule.create!(menu:, date: Date.current, amount: 10)
  end

  def choose_option(label, option)
    find("[role=combobox][aria-label='#{label}']").click
    page.document.find("[role=option]", text: option, exact_text: true).click
  end

  def open_dish
    visit dashboard_path
    without_animations
    click_button "Agregar Milanesa al pan"
    click_button "Agregar Milanesa al pan" unless page.has_button?("Volver", wait: 2)
  end

  it "RRHH crea el cupón y solo el empleado elegido lo ve y lo usa" do
    sign_in users(:admin), role: :admin
    visit admin_benefit_configurations_path
    without_animations
    click_button "Agregar"

    within("[role=dialog]") do
      fill_in "Nombre del subsidio", with: "Premio del mes"
      fill_in "% de descuento", with: "30"
      find("label", text: "Seleccionar empleados").click
      find('input[name="employee_search"]').set("Test")
      click_button "Test User", exact: true
      choose_option "Condición", "Cupón"
    end

    # El calendario abre en un portal fuera del sheet.
    pick_date "#condition_effective_from", Date.current, opens_at: @real_today

    within("[role=dialog]") do
      fill_in "condition_limit", with: "1"
      fill_in "condition_validity_amount", with: "1"
      choose_option "Unidad de validez", "semanas"
      click_button "Agregar"
    end

    expect(page).to have_no_css("[role=dialog]")
    expect(page).to have_content("Premio del mes")
    expect(page).to have_content("Cupón")

    sign_in users(:one), role: :consumer
    open_dish

    # 300 con 50% base (- $150) y 30% de cupón (- $90): paga 60.
    expect(find("span", text: "Premio del mes (30%)", exact_text: true).sibling("span")).to have_text("- $90")
    expect(find("span", text: "Monto a pagar", exact_text: true).sibling("span")).to have_text("$60")

    visit profile_path
    within(find("section[aria-labelledby=benefit-title]")) do
      expect(find("dt", text: "Premio del mes").find(:xpath, "following-sibling::dd")).to have_text("30%")
    end

    sign_in users(:other_consumer_user), role: :consumer
    open_dish

    expect(page).to have_no_content("Premio del mes")
    visit profile_path
    expect(page).to have_no_content("Premio del mes")
  end
end
