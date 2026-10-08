# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pedir durante el fin de semana", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :benefit_configurations, :benefits

  let(:saturday) { Date.current.next_occurring(:saturday).noon }
  let(:next_monday) { saturday.to_date.next_week(:monday) }

  before do
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
  end

  it "muestra el menú de la semana que viene un sábado y permite completar el pedido" do
    Schedule.create!(menu: menus(:milanesa), date: next_monday, amount: 10)

    travel_to(saturday) do
      sign_in users(:one), role: :consumer
      visit dashboard_path

      expect(page).to have_content("Milanesa con papas fritas")
      expect(page).to have_content(users(:provider_user).name)

      click_button "Agregar Milanesa con papas fritas"

      expect(page).to have_content("Notas para este plato")
      click_button "Agregar"

      first(:button, "Ver carrito").click

      expect(page).to have_content("Tu carrito")
      expect(page).to have_content("Milanesa con papas fritas x1")

      click_button "Confirmar pedido"

      expect(page).to have_content("¡Pedido recibido!")
      expect(page).to have_content("Milanesa con papas fritas")

      click_link "Ver mis pedidos"
      expect(page).to have_current_path(orders_path)
    end
  end

  it "asigna el pedido al beneficio del mes siguiente y a la cuenta del mes de entrega al pedir en el último sábado del mes" do
    last_saturday = Time.zone.local(2026, 10, 31, 14, 0)
    delivery_date = Date.new(2026, 11, 2)
    Schedule.create!(menu: menus(:milanesa), date: delivery_date, amount: 10)

    consumer = consumers(:one)
    config = benefit_configurations(:monthly)
    benefits(:monthly).update!(
      due_date: Date.new(2026, 10, 31),
      status: :current,
      amount: 20,
      percentage: 50
    )
    future_benefit = Benefit.create!(
      consumer:,
      benefit_configuration: config,
      amount: 20,
      percentage: 50,
      due_date: Date.new(2026, 11, 30),
      status: :future
    )

    travel_to(last_saturday) do
      sign_in users(:one), role: :consumer
      visit dashboard_path

      expect(page).to have_content("Milanesa con papas fritas")

      click_button "Agregar Milanesa con papas fritas"
      expect(page).to have_content("Notas para este plato")
      click_button "Agregar"

      first(:button, "Ver carrito").click
      expect(page).to have_content("Tu carrito")

      click_button "Confirmar pedido"

      expect(page).to have_content("¡Pedido recibido!")

      order = Order.last
      expect(order.order_benefits.map(&:benefit)).to contain_exactly(future_benefit)
      expect(order.accounts.pluck(:month).uniq).to contain_exactly(Date.new(2026, 11, 1))
    end
  end
end
