# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cierre programado visto por el empleado", type: :system do
  fixtures :users, :providers, :consumers, :companies, :menus, :schedules

  let(:monday) { Date.current.next_week(:monday) }
  let(:tuviandita) { providers(:tuviandita) }
  let(:endulzate) { providers(:endulzate) }
  let(:consumer_user) { users(:one) }

  around do |example|
    travel_to(Time.zone.local(monday.year, monday.month, monday.day, 10, 0)) { example.run }
  end

  before do
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    tuviandita.closures.destroy_all
    endulzate.closures.destroy_all

    milanesa = Menu.create!(provider: tuviandita, name: "Milanesa de carne", description: "Con papas", price: 320)
    Schedule.create!(date: monday, amount: 10, menu: milanesa)

    sorrentinos = Menu.create!(provider: endulzate, name: "Sorrentinos de jamón y queso", description: "Con salsa", price: 300)
    Schedule.create!(date: monday, amount: 10, menu: sorrentinos)
  end

  it "muestra el aviso de cierre, oculta los platos del proveedor cerrado y mantiene disponibles los del otro proveedor" do
    tuviandita.closures.create!(starts_on: monday, ends_on: monday + 2.days, reason: "Vacaciones anuales")

    sign_in consumer_user, role: :consumer
    visit_hydrated dashboard_path

    provider_name = tuviandita.user.name

    # Aviso del cierre
    expect(page).to have_content("#{provider_name} no está disponible")
    expect(page).to have_content("Vacaciones anuales")

    # Criterio 1: los platos del proveedor cerrado no se pueden pedir
    expect(page).to have_no_content("Milanesa de carne")

    # Criterio 5: los platos del otro proveedor sí están disponibles y se pueden agregar
    expect(page).to have_content("Sorrentinos de jamón y queso")
    expect(page).to have_button("Agregar Sorrentinos de jamón y queso", disabled: false)

    # El aviso se puede descartar
    click_button "Cerrar aviso"
    expect(page).to have_no_content("#{provider_name} no está disponible")
  end

  it "conserva el proveedor y el período del cierre después de descartar el aviso" do
    tuviandita.closures.create!(starts_on: monday, ends_on: monday + 2.days, reason: "Obras en cocina")

    sign_in consumer_user, role: :consumer
    visit_hydrated dashboard_path

    provider_name = tuviandita.user.name

    find("button[aria-label='Filtrar por proveedores']").click
    within("[data-provider-filter-sheet]") do
      all("[role=checkbox]").reject { |checkbox| checkbox[:id] == "dashboard-filter-all" || checkbox[:id] == "dashboard-filter-#{tuviandita.id}" }.each(&:click)
      click_button "Aplicar"
    end

    click_button "Cerrar aviso"

    expect(page).to have_no_content("#{provider_name} no está disponible")
    expect(page).to have_content("#{provider_name} no recibirá pedidos del #{I18n.l(monday, format: :short)} al #{I18n.l(monday + 2.days, format: :short)}")
    expect(page).to have_no_content("Milanesa de carne")
  end
end
