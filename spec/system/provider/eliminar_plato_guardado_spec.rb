# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Eliminar un plato guardado como proveedor", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  before do
    sign_in provider_user, role: :provider
  end

  it "elimina el plato y avisa que se puede volver a crear" do
    menu = Menu.create!(provider:, name: "Tarta de jamón y queso", description: "De masa integral", price: 300)

    visit schedules_path(tab: "saved")

    within(find("[data-slot=card]", text: menu.name)) { click_button "Eliminar" }
    within("[role=dialog]") do
      expect(page).to have_content("¿Eliminar plato guardado?")
      click_button "Eliminar"
    end

    expect(page).to have_content("Plato eliminado")
    expect(page).to have_content("El plato se eliminó de tus platos guardados. Podés volver a crearlo cuando quieras.")

    click_button "Listo"

    expect(page).to have_no_content(menu.name)
    # No se borra de la base: se archiva, para no perder el historial de pedidos.
    expect(menu.reload.archived_at).to be_present
  end

  it "muestra el vacío cuando no queda ningún plato guardado" do
    provider.menus.find_each { it.update!(archived_at: Time.current) }

    visit schedules_path(tab: "saved")

    expect(page).to have_content("No tenés platos guardados")
    expect(page).to have_content("Importá o agregá platos para incluirlos al menú cuando quieras.")
  end
end
