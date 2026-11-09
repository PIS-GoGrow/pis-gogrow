# frozen_string_literal: true

require "rails_helper"

# Regresión del defecto de los chips de días en "Platos guardados": además de
# los días configurados, tienen que marcar los días ya publicados en la semana
# elegida. Un plato con repetición semanal se marca en todas las semanas; uno
# publicado sin repetición, solo en la semana en que está publicado.
RSpec.describe "Chips de días en Platos guardados", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:monday) { Date.current }
  let(:tuesday) { monday + 1.day }
  let(:next_tuesday) { monday + 8.days }

  before do
    page.current_window.resize_to(375, 667)
    Order.destroy_all
    Schedule.destroy_all
    sign_in provider_user, role: :provider

    @recurring = Menu.create!(
      provider:,
      name: "Guiso de lentejas",
      description: "Con verduras",
      price: 300
    )
    @recurring.agendas.create!(starts_on: monday, weekdays: [ 1, 3 ])

    @single = Menu.create!(
      provider:,
      name: "Tarta de verduras",
      description: "Con masa integral",
      price: 280
    )
    @single.schedules.create!(date: tuesday)
  end

  def open_saved_tab(date)
    visit_hydrated new_provider_menu_path(date: date.iso8601)
    without_animations
    click_on "Platos guardados"
    wait_for_hydration
  end

  def dish_card(name)
    find("[data-slot=card]", text: name)
  end

  it "marca la repetición en cualquier semana y el día suelto solo en su semana" do
    open_saved_tab(monday)

    recurring_card = dish_card(@recurring.name)
    expect(recurring_card).to have_content("Lunes, Miércoles")
    # Los chips son de solo lectura.
    expect(recurring_card).to have_css("[inert][aria-hidden='true']")
    expect(dish_card(@single.name)).to have_content("Martes")

    open_saved_tab(next_tuesday)

    expect(dish_card(@recurring.name)).to have_content("Lunes, Miércoles")
    expect(dish_card(@single.name)).to have_no_css("[data-state='on']")
  end
end
