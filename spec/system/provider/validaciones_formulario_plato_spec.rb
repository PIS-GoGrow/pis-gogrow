# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validaciones del formulario de plato en español", type: :system do
  fixtures :users, :providers, :menus, :schedules

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:publish_date) { Date.new(2030, 1, 8) }

  around do |example|
    travel_to(Time.zone.local(2030, 1, 7, 10, 0)) { example.run }
  end

  before do
    sign_in provider_user, role: :provider
    visit_hydrated new_provider_menu_path(date: publish_date.iso8601)
    without_animations
  end

  it "muestra todos los campos requeridos vacíos a la vez en español al enviar sin completar" do
    find('button[type="submit"]', text: "Agregar", exact_text: true).click

    expect(page).to have_css("[data-invalid=true]", count: 3)
    expect(page).to have_content("No puede estar vacío.", count: 3)
  end

  it "muestra error en español junto al precio cuando es 0 o negativo sin mostrar globos del navegador" do
    fill_in "name", with: "Wok de verduras"
    fill_in "description", with: "Salteado con arroz"
    fill_in "price", with: "0"

    find('button[type="submit"]', text: "Agregar", exact_text: true).click

    expect(page).to have_content("Tiene que ser mayor que 0.")

    fill_in "price", with: "-15"
    find('button[type="submit"]', text: "Agregar", exact_text: true).click

    expect(page).to have_content("Tiene que ser mayor que 0.")
  end
end
