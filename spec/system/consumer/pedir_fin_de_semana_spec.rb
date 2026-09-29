# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pedir durante el fin de semana", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus

  let(:saturday) { Date.current.next_occurring(:saturday).noon }
  let(:next_monday) { saturday.to_date.next_week(:monday) }

  before do
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    Benefit.create!(consumer: consumers(:one), description: "Viandas mensuales", amount: 20, percentage: 50, due_date: 1.month.from_now)
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
end
