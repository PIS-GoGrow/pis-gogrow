# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consulta de platos disponibles" do
  fixtures :users, :companies, :consumers, :providers, :menus, :schedules

  it "lista los platos disponibles por fecha más próxima y permite ver el detalle de uno" do
    sign_in(users(:one), role: :consumer)

    visit menus_path

    expect(page).to have_content("Platos disponibles")
    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_content("Empanadas de carne")
    expect(page).to have_no_content("Ensalada César")
    expect(page).to have_no_content("Tarta de verduras")
    expect(page).to have_no_content("Guiso de lentejas")
    expect(page.text.index("Milanesa con papas fritas")).to be < page.text.index("Empanadas de carne")

    click_on "Ver", match: :first

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_content("Opción de carne o pollo")
    expect(page).to have_content("Por Another User")
    expect(page).to have_content("300")
    expect(page).to have_content("Cupo: 7")
  end

  it "muestra el estado vacío cuando no hay platos disponibles" do
    Schedule.destroy_all

    sign_in(users(:one), role: :consumer)
    visit menus_path

    expect(page).to have_content("No hay platos disponibles")
    expect(page).to have_content("Los proveedores todavía no publicaron platos para los próximos días.")
  end
end
