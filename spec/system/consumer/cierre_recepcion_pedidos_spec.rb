# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cierre de recepción de pedidos visto por el empleado" do
  fixtures :users, :providers, :consumers, :companies

  let(:closed_message) { "Este proveedor ya cerró la recepción de pedidos para hoy." }
  # Un lunes futuro: el servidor lo toma como "hoy" y el navegador, que no viaja en el
  # tiempo, no lo marca como fecha pasada.
  let(:monday) { Date.current.next_week(:monday) }

  around do |example|
    travel_to(Time.zone.local(monday.year, monday.month, monday.day, 12, 0)) { example.run }
  end

  before do
    Order.delete_all
    Schedule.delete_all
    providers(:endulzate).update!(order_deadline: nil)
    Schedule.create!(date: monday, amount: 5, menu: Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan", price: 300))
    Schedule.create!(date: monday, amount: 5, menu: Menu.create!(provider: providers(:endulzate), name: "Ñoquis caseros", price: 280))
  end

  def set_deadline_as_provider(value)
    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path
    fill_in "Hora límite", with: Time.zone.parse(value)
    click_on "Guardar"
    expect(page).to have_content(I18n.t("flash.order_deadline_updated"))
    sign_out
  end

  def visit_menu_as_consumer
    sign_in users(:one), role: :consumer
    visit dashboard_path
  end

  it "closes only the provider whose deadline already passed" do
    set_deadline_as_provider("11:00")

    visit_menu_as_consumer

    expect(page).to have_content(closed_message, count: 1)
    expect(page).to have_button("Agregar Milanesa al pan", disabled: true)
    expect(page).to have_button("Agregar Ñoquis caseros", disabled: false)
  end

  it "reopens the menu when the provider moves the deadline later" do
    set_deadline_as_provider("11:00")
    visit_menu_as_consumer
    expect(page).to have_button("Agregar Milanesa al pan", disabled: true)
    sign_out

    set_deadline_as_provider("13:00")
    visit_menu_as_consumer

    expect(page).to have_no_content(closed_message)
    expect(page).to have_button("Agregar Milanesa al pan", disabled: false)
  end

  it "keeps the menu open while the deadline has not arrived" do
    set_deadline_as_provider("12:01")

    visit_menu_as_consumer

    expect(page).to have_no_content(closed_message)
    expect(page).to have_button("Agregar Milanesa al pan", disabled: false)
  end
end
