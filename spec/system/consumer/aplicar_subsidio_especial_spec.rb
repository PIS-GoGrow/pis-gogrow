# frozen_string_literal: true

require "rails_helper"

# Defecto ClickUp 86e3me31f (IBP-037 / IBP-006): con un subsidio especial
# asignado por RRHH, el empleado solo veía descontado el subsidio general.
RSpec.describe "Aplicar un subsidio especial al pedir", type: :system do
  fixtures :users, :companies, :admins, :consumers, :providers, :benefit_configurations, :benefit_rules, :benefits

  let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan", description: "Con papas", price: 300) }

  around do |example|
    # El navegador no ve travel_to y marca como pasados los días anteriores a hoy.
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    # Los fixtures gift y seniority son subsidios especiales sin nombre que la
    # pantalla de RRHH mostraría vacíos.
    benefit_configurations(:gift, :seniority).each(&:destroy)
    benefits(:monthly).update!(percentage: 50, amount: 20, due_date: Date.current.end_of_month, status: :current)
    Schedule.create!(menu:, date: Date.current, amount: 10)
  end

  def choose_option(label, option)
    find("[role=combobox][aria-label='#{label}']").click
    page.document.find("[role=option]", text: option, exact_text: true).click
  end

  it "descuenta el subsidio general y el especial en el plato, el carrito, el pedido guardado, la Cuenta y la ficha de RRHH" do
    sign_in users(:admin), role: :admin
    visit admin_benefit_configurations_path
    without_animations

    expect(page).to have_content("No hay subsidios especiales")
    click_button "Agregar"

    within("[role=dialog]") do
      expect(page).to have_content("Agregar subsidio especial")
      expect(page).to have_button("Agregar", disabled: true)

      fill_in "Nombre del subsidio", with: "Antigüedad"
      fill_in "% de descuento", with: "25"
      find("label", text: "Seleccionar empleados").click
      find('input[name="employee_search"]').set("Test")
      expect(page).to have_button("Test User", exact: true)
      click_button "Test User", exact: true
      choose_option "Condición", "Antigüedad"
      fill_in "Es mayor a", with: "2"
      click_button "Agregar"
    end

    expect(page).to have_no_css("[role=dialog]")
    expect(page).to have_content("Antigüedad")

    sign_in users(:one), role: :consumer
    visit dashboard_path
    without_animations

    click_button "Agregar Milanesa al pan"
    click_button "Agregar Milanesa al pan" unless page.has_button?("Volver", wait: 2)

    # 300 con 50% + 25%, en una sola línea como en Figma: paga 75.
    expect(find("span", text: "Beneficio GoGrow (75%)", exact_text: true).sibling("span")).to have_text("- $225")
    expect(page).to have_no_content("Antigüedad (25%)")
    expect(find("span", text: "Monto a pagar", exact_text: true).sibling("span")).to have_text("$75")
    click_button "Agregar"

    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
    expect(find("span", text: "Beneficio GoGrow (75%)", exact_text: true).sibling("span")).to have_text("- $225")
    expect(find("span", text: "Monto a pagar", exact_text: true).sibling("span")).to have_text("$75")

    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")

    order = Order.last
    expect(order).to have_attributes(price: 300, discounted_price: 75)
    expect(order.benefits.map(&:description)).to contain_exactly("Antigüedad", benefits(:monthly).description)

    visit order_path(order)
    expect(find("dt", text: "Subsidio aplicado").find(:xpath, "following-sibling::dd")).to have_text("225")
    expect(find("dt", text: "Importe final").find(:xpath, "following-sibling::dd")).to have_text("75")

    visit profile_path
    within(find("section[aria-labelledby=benefit-title]")) do
      expect(page).to have_css("strong", text: "75%")
      expect(find("dt", text: "Subsidio Base").find(:xpath, "following-sibling::dd")).to have_text("50%")
      expect(find("dt", text: "Antigüedad").find(:xpath, "following-sibling::dd")).to have_text("25%")
    end

    sign_in users(:admin), role: :admin
    visit admin_consumer_path(consumers(:one))
    expect(page).to have_css("strong", text: "75%")
    expect(find("dt", text: "Subsidio Base").find(:xpath, "following-sibling::dd")).to have_text("50%")
    expect(find("dt", text: "Antigüedad").find(:xpath, "following-sibling::dd")).to have_text("25%")
  end
end
