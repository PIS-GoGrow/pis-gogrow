# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configurar grupos de opciones obligatorios y opcionales", type: :system do
  fixtures :users, :providers, :menus

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  before do
    sign_in provider_user, role: :provider
  end

  def open_add_group_sheet
    find("button.-mr-2", text: "Agregar").click
  end

  it "permite al proveedor marcar grupos como obligatorios u opcionales y muestra los indicadores en la lista" do
    visit_hydrated new_provider_menu_path

    fill_in "name", with: "Canelones caseros"
    fill_in "price", with: "380"
    fill_in "description", with: "Con salsa y relleno a elección"

    # 1. Agregar grupo obligatorio
    open_add_group_sheet

    within("[role=dialog]") do
      fill_in "group-name", with: "Relleno"
      fill_in "group-options", with: "Carne, Verdura"
      find("#group-required").click
      click_button "Agregar"
    end

    expect(page).to have_content("Relleno")
    expect(page).to have_content("Carne, Verdura")
    expect(page).to have_content("Obligatorio")

    # 2. Agregar grupo opcional (default sin tocar switch)
    open_add_group_sheet

    within("[role=dialog]") do
      fill_in "group-name", with: "Salsa"
      fill_in "group-options", with: "Filetto, Blanca"
      click_button "Agregar"
    end

    expect(page).to have_content("Salsa")
    expect(page).to have_content("Filetto, Blanca")
    expect(page).to have_content("Opcional")

    # 3. Guardar el plato
    within("form") do
      first("button[type=submit]", text: "Agregar").click
    end

    expect(page).to have_content("¡Plato agregado!")

    # 4. Validar integridad en base de datos
    created_menu = provider.menus.find_by!(name: "Canelones caseros")
    relleno_group = created_menu.option_groups.find_by!(name: "Relleno")
    salsa_group = created_menu.option_groups.find_by!(name: "Salsa")

    expect(relleno_group.required).to be(true)
    expect(salsa_group.required).to be(false)
  end
end
