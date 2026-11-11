# frozen_string_literal: true

require "rails_helper"

# SC-008: desde el detalle de un plato que ya está en el carrito, la papelera lo
# quita y devuelve al menú semanal.
RSpec.describe "Quitar un plato del carrito desde su detalle", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus,
           :benefit_configurations, :benefits

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:milanesa) { menus(:milanesa) }
  let(:dish) { "Agregar Milanesa con papas fritas" }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    @schedule = Schedule.create!(menu: milanesa, date: monday)

    page.current_window.resize_to(1400, 1400)
    sign_in users(:one), role: :consumer
  end

  def add_to_cart_and_reopen
    visit_hydrated dashboard_path
    click_button dish
    click_button "Agregar"
    expect(page).to have_content("1 platos")

    click_button dish
    expect(page).to have_button("Modificar")
  end

  it "quita el plato, vuelve al menú y no lo recupera al recargar" do
    add_to_cart_and_reopen

    click_button "Quitar"

    expect(page).to have_button(dish)
    expect(page).to have_no_button("Modificar")
    expect(page).to have_no_content("Agregado")
    expect(page).to have_content("0 platos")

    visit_hydrated dashboard_path
    expect(page).to have_button(dish)
    expect(page).to have_content("0 platos")
  end

  it "no toca el pedido ya hecho del mismo plato" do
    Order.create!(consumer: consumers(:one), schedule: @schedule, amount: 2, price: milanesa.price * 2,
                  address: consumers(:one).company.address, delivery_method: :office)
    add_to_cart_and_reopen

    click_button "Quitar"

    expect(page).to have_content("0 platos")
    expect(page).to have_css('[data-status="pending"]', text: "Pendiente")
    expect(page).to have_button(dish, text: "2", class: "bg-amber-500")
    expect(Order.sole).to have_attributes(status: "pending", amount: 2)
  end
end
