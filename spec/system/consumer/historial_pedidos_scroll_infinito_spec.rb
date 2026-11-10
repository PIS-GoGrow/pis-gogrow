# frozen_string_literal: true

require "rails_helper"

# Regresión del defecto B1: el historial de "Mis pedidos" cortaba en los
# últimos 3 meses por created_at. Ahora la primera carga son los pedidos
# entregados en los últimos 3 meses (por fecha de entrega) y el scroll trae
# los anteriores de a 20, sin límite temporal.
RSpec.describe "Historial de pedidos con scroll infinito", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:consumer) { consumers(:one) }
  let(:provider) { providers(:tuviandita) }
  let(:history_menu) do
    Menu.create!(provider:, name: "Menú historial", description: "Para el historial", price: 300)
  end

  before do
    Order.destroy_all
    page.current_window.resize_to(375, 667)
    sign_in users(:one), role: :consumer
  end

  def create_history_order(delivery_date:, menu_name:, created_at: nil)
    schedule = Schedule.create!(menu: history_menu, date: delivery_date)

    Order.create!(
      consumer:,
      schedule:,
      status: :confirmed,
      delivery_method: :office,
      amount: 1,
      price: 300.50,
      discounted_price: 150.25,
      menu_name:,
      created_at: created_at || Time.current
    )
  end

  it "carga por scroll los pedidos entregados antes de los últimos 3 meses" do
    # 25 pedidos recientes arman una primera página suficientemente larga como
    # para que el scroll sea necesario. Uno de ellos se creó hace 4 meses: lo
    # que manda para el historial es la fecha de entrega.
    25.times do |index|
      create_history_order(
        delivery_date: Date.current - (index + 1).days,
        menu_name: "Reciente #{index + 1}",
        created_at: (index == 4 ? 4.months.ago : Time.current)
      )
    end

    create_history_order(
      delivery_date: Date.current - 4.months,
      menu_name: "Guiso de lentejas"
    )

    visit_hydrated orders_path
    without_animations
    find("[role=tab]", text: "Historial").click

    expect(page).to have_content("Reciente 1")
    expect(page).to have_content("Reciente 5")
    expect(page.text.index("Reciente 1")).to be < page.text.index("Reciente 2")

    # Los anteriores a 3 meses todavía no están cargados.
    expect(page).to have_no_content("Guiso de lentejas")

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    expect(page).to have_content("Guiso de lentejas")
    expect(page).to have_current_path(orders_path)
  end
end
