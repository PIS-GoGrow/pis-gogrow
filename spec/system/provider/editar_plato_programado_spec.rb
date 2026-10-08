# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edición de plato programado en el menú (flujo complejo)", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }
  let(:target_date) { Date.current.next_occurring(:thursday) }

  before do
    sign_in provider_user, role: :provider
    Schedule.where(date: target_date).destroy_all
  end

  it "modifica solo para un día y rechaza los pedidos confirmados afectados" do
    schedule = milanesa.schedules.create!(date: target_date, amount: 10)
    order = Order.create!(
      consumer: consumers(:one),
      schedule:,
      status: :confirmed,
      amount: 1,
      price: 350,
      delivery_method: :office
    )

    visit edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    expect(page).to have_content(milanesa.name)

    fill_in "name", with: "Milanesa Especial del Día", fill_options: { clear: :backspace }

    click_button "Modificar"

    # Se abre la hoja de confirmación (Radix RadioGroup usa botones dentro de label)
    expect(page).to have_content("Modificar solo para este día")
    find("label", text: "Modificar solo para este día").click

    # Al tener pedidos confirmados, se requiere el paso intermedio
    click_button "Continuar"

    expect(page).to have_content("Rechazar los pedidos confirmados")
    find("label", text: "Rechazar los pedidos confirmados").click

    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")

    # Verificar que el plato guardado no cambió su nombre original
    expect(milanesa.reload.name).to eq("Milanesa con papas fritas")

    # Verificar que la programación del día apunta a una variante con el nombre nuevo
    expect(schedule.reload.menu.name).to eq("Milanesa Especial del Día")
    expect(schedule.menu.base_menu).to eq(milanesa)

    # Verificar que el pedido confirmado fue rechazado con motivo dish_modified
    expect(order.reload).to be_rejected
    expect(order).to be_rejection_reason_dish_modified
  end

  it "modifica solo para un día y mantiene los pedidos confirmados" do
    schedule = milanesa.schedules.create!(date: target_date, amount: 10)
    order = Order.create!(
      consumer: consumers(:one),
      schedule:,
      status: :confirmed,
      amount: 1,
      price: 350,
      delivery_method: :office
    )

    visit edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    expect(page).to have_content(milanesa.name)

    fill_in "name", with: "Milanesa con Salsa Criolla", fill_options: { clear: :backspace }

    click_button "Modificar"

    expect(page).to have_content("Modificar solo para este día")
    find("label", text: "Modificar solo para este día").click

    click_button "Continuar"

    expect(page).to have_content("Mantener los pedidos confirmados")
    find("label", text: "Mantener los pedidos confirmados").click

    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa con papas fritas")
    expect(schedule.reload.menu.name).to eq("Milanesa con Salsa Criolla")

    # El pedido sigue confirmado y conserva el nombre anterior
    expect(order.reload).to be_confirmed
    expect(order.menu_name).to eq("Milanesa con papas fritas")
  end
end
