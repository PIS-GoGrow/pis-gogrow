# frozen_string_literal: true

require "rails_helper"

# SC-008: desde el menú semanal el empleado ve sobre cada plato qué pidió y si
# el proveedor ya le respondió, sin entrar al detalle ni ir a "Pedidos".
RSpec.describe "Estado del pedido en el menú semanal del consumidor", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus,
           :benefit_configurations, :benefits

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:milanesa) { menus(:milanesa) }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    Schedule.create!(menu: milanesa, date: monday)

    page.current_window.resize_to(1400, 1400)
    sign_in users(:one), role: :consumer
  end

  def order_milanesa
    visit_hydrated dashboard_path
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"
    click_link "Ver carrito"
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
  end

  it "marca el plato como pendiente y lo pasa a confirmado cuando el proveedor lo acepta" do
    order_milanesa

    visit_hydrated dashboard_path

    expect(page).to have_css('[data-status="pending"]', text: "Pendiente")
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "1")

    Order.sole.decide(:confirmed)

    visit_hydrated dashboard_path

    expect(page).to have_css('[data-status="confirmed"]', text: "Confirmado")
    expect(page).to have_no_css('[data-status="pending"]')
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "1")
  end

  it "muestra confirmado cuando el proveedor lo confirma desde su pantalla, igual que en Mis pedidos" do
    order_milanesa
    order = Order.sole
    sign_out

    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_order_path(order)
    click_button "Confirmar"
    expect(page).to have_content("Pedido confirmado")
    sign_out

    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_path

    expect(page).to have_css('[data-status="confirmed"]', text: "Confirmado")
    expect(page).to have_no_css('[data-status="pending"]')
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "1", class: "bg-green-600")

    visit_hydrated orders_path
    expect(page).to have_css('[data-status="confirmed"]', text: "Confirmado")
  end

  it "deja de marcar el plato cuando el proveedor lo rechaza desde su pantalla" do
    order_milanesa
    order = Order.sole
    sign_out

    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_order_path(order)
    click_button "Rechazar"
    find("label", text: "Otro motivo").click
    fill_in "rejection-details", with: "Sin insumos", fill_options: { rapid: false }
    click_button "Rechazar pedido"
    expect(page).to have_content("Pedido rechazado")
    sign_out

    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_path

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_no_css("[data-status]")
    expect(find_button("Agregar Milanesa con papas fritas").text).to eq("")
  end

  it "no marca nada sobre un plato que el empleado no pidió" do
    visit_hydrated dashboard_path

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_no_css('[data-status="pending"]')
    expect(page).to have_no_css('[data-status="confirmed"]')
  end

  it "deja de marcar el plato cuando el pedido se cancela" do
    order_milanesa

    expect(Order.sole.cancel(by: users(:one))).to be(true)

    visit_hydrated dashboard_path

    expect(page).to have_no_css('[data-status="pending"]')
    expect(page).to have_no_css('[data-status="confirmed"]')
  end
end
