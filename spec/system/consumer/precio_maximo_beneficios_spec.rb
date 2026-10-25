# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Precio máximo en beneficios al ordenar viandas", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules,
           :benefit_configurations, :benefits

  let(:consumer_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:provider) { providers(:tuviandita) }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    # Subsidio mensual del 50% con precio máximo de $250
    consumer.benefits.destroy_all
    consumer.benefits.create!(
      benefit_configuration: benefit_configurations(:monthly),
      description: "Subsidio Base GoGrow",
      percentage: 50,
      amount: 20,
      max_price: 250,
      due_date: Date.current.end_of_month,
      status: :current
    )

    # Plato caro ($350) que supera el precio máximo
    @expensive_menu = Menu.create!(
      provider: provider,
      name: "Salmón Grillado",
      description: "Con verduras al vapor",
      price: 350
    )
    @expensive_schedule = Schedule.create!(menu: @expensive_menu, date: Date.current, amount: 10)

    # Plato accesible ($200) dentro del precio máximo
    @affordable_menu = Menu.create!(
      provider: provider,
      name: "Tarta de Acelga",
      description: "Porción individual",
      price: 200
    )
    @affordable_schedule = Schedule.create!(menu: @affordable_menu, date: Date.current, amount: 10)

    sign_in consumer_user, role: :consumer
  end

  it "aplica el subsidio únicamente a las viandas cuyo precio no supera el límite configurado" do
    visit dashboard_path
    without_animations

    # Agregar el plato caro ($350 > $250)
    click_button "Agregar Salmón Grillado"
    expect(page).to have_content("Salmón Grillado")
    click_button "Agregar"

    # Agregar el plato económico ($200 <= $250)
    click_button "Agregar Tarta de Acelga"
    expect(page).to have_content("Tarta de Acelga")
    click_button "Agregar"

    # Abrir el carrito
    click_link "Ver carrito"
    expect(page).to have_content("Tu carrito")
    expect(page).to have_content("Salmón Grillado")
    expect(page).to have_content("Tarta de Acelga")

    # Alerta informando que 1 vianda tiene beneficio y 1 se cobra a precio completo
    expect(page).to have_content("De este pedido, 1 con beneficio y 1 a precio completo.")

    # Confirmar pedido
    expect(page).to have_button("Confirmar pedido", disabled: false)
    click_button "Confirmar pedido"

    expect(page).to have_content("¡Pedido recibido!")

    # Verificación de integridad en la base de datos
    expensive_order = consumer.orders.find_by(schedule: @expensive_schedule)
    affordable_order = consumer.orders.find_by(schedule: @affordable_schedule)

    expect(expensive_order).to be_present
    expect(expensive_order.price).to eq(350)
    expect(expensive_order.discounted_price).to eq(350)
    expect(expensive_order.order_benefits).to be_empty

    expect(affordable_order).to be_present
    expect(affordable_order.price).to eq(200)
    expect(affordable_order.discounted_price).to eq(100)
    expect(affordable_order.order_benefits.count).to eq(1)
    expect(affordable_order.order_benefits.first.benefit_used).to eq(1)
  end
end
