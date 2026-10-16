# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reset del formulario después de agregar un plato", type: :system do
  fixtures :users, :providers, :menus, :schedules

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:publish_date) { Date.new(2030, 1, 8) }

  around do |example|
    travel_to(Time.zone.local(2030, 1, 7, 10, 0)) { example.run }
  end

  before do
    sign_in provider_user, role: :provider
    visit new_provider_menu_path(date: publish_date.iso8601)
    without_animations
  end

  def add_new_dish(name)
    fill_in "description", with: "Descripción de prueba"
    fill_in "price", with: "320"
    fill_in "name", with: name
    expect(page).to have_field("name", with: name)

    expect do
      find('button[type="submit"]', text: "Agregar", exact_text: true).click
      expect(page).to have_content("¡Plato agregado!")
    end.to change(provider.menus, :count).by(1)
  end

  def expect_clean_form(date_label)
    expect(page).to have_field("name", with: "")
    expect(page).to have_field("description", with: "")
    expect(page).to have_field("price", with: "")
    expect(find("#agenda-date")).to have_text(date_label)
  end

  it "limpia el formulario al cerrar la confirmación con Escape y evita reenviar el plato" do
    date_label = find("#agenda-date").text
    add_new_dish("Tarta de verduras")

    page.send_keys(:escape)

    expect(page).to have_no_content("¡Plato agregado!")
    expect_clean_form(date_label)
    expect do
      find('button[type="submit"]', text: "Agregar", exact_text: true).click
      expect(page).to have_css("[data-invalid=true]")
    end.not_to change(provider.menus, :count)
  end

  it "limpia el formulario al seguir agregando y al cerrar haciendo clic fuera" do
    date_label = find("#agenda-date").text
    add_new_dish("Canelones")

    click_button "Seguir agregando"

    expect_clean_form(date_label)
    add_new_dish("Ravioles")

    overlay = find('[data-slot="dialog-overlay"]')
    overlay.click(x: 10, y: 10)

    expect(page).to have_no_content("¡Plato agregado!")
    expect_clean_form(date_label)
  end

  it "conserva el contexto de platos guardados y el destino de volver al menú" do
    click_on "Platos guardados"
    fill_in "Buscar plato", with: "Milanesa"
    find('[aria-label="Filtrar platos"]').click
    find('[role="option"]', text: "Disponibles").click
    click_button "Agregar #{menus(:milanesa).name} a la selección"

    click_button "Agregar", exact: true
    expect(page).to have_content("¡Plato agregado!")
    expect(find_link("Volver a Menú")[:href]).to end_with(schedules_path(date: publish_date.iso8601))

    page.send_keys(:escape)

    expect(find('[role="tab"][aria-selected="true"]')).to have_text("Platos guardados")
    expect(page).to have_field("Buscar plato", with: "Milanesa")
    expect(find('[aria-label="Filtrar platos"]')).to have_text("Disponibles")
    expect(page).to have_button("Agregar", exact: true, disabled: true)
  end
end
