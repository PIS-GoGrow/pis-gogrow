# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configuración de subsidios especiales por RRHH", type: :system do
  fixtures :users, :companies, :admins, :consumers, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }
  let(:company) { companies(:gogrow) }

  before do
    # Los fixtures gift y seniority son configuraciones sin MonthlyBenefit: para la
    # pantalla serían subsidios especiales sin nombre.
    benefit_configurations(:gift, :seniority).each(&:destroy)
    sign_in admin_user, role: :admin
  end

  def choose_option(label, option)
    find("[role=combobox][aria-label='#{label}']").click
    # Radix abre las opciones en un portal fuera del sheet, así que se buscan en
    # todo el documento y no dentro del within("[role=dialog]") que lo llama.
    page.document.find("[role=option]", text: option, exact_text: true).click
  end

  it "permite agregar un subsidio especial para empleados seleccionados" do
    visit admin_benefit_configurations_path

    expect(page).to have_content("No hay subsidios especiales")

    click_button "Agregar"

    within("[role=dialog]") do
      expect(page).to have_content("Agregar subsidio especial")
      expect(page).to have_button("Agregar", disabled: true)

      fill_in "Nombre del subsidio", with: "2 años"
      fill_in "% de descuento", with: "25"
      find("[role=radio]#applies_to_selection").click

      # Esperar a que el input esté disponible
      find('input[name="employee_search"]').set("Test")
      expect(page).to have_button("Test User", exact: true)
      click_button "Test User", exact: true
      expect(page).to have_no_button("Test User", exact: true)
      expect(page).to have_content("Test U.")

      choose_option "Condición", "Antigüedad"
      fill_in "Es mayor a", with: "2"

      click_button "Agregar"
    end

    expect(page).to have_no_css("[role=dialog]")
    expect(page).to have_content("2 años")
    expect(page).to have_content("25%")
    expect(page).to have_content("Selección")
    expect(page).to have_content("Antigüedad")

    configuration = company.benefit_configurations.find_by!(name: "2 años")
    expect(configuration.consumers).to eq([ consumers(:one) ])
    expect(configuration.benefit_rules.sole).to have_attributes(type: "SeniorityBenefit", min_years: 2)
  end

  context "con un subsidio especial cargado" do
    let!(:special) do
      company.benefit_configurations.new(created_by: admin_user).tap do |configuration|
        configuration.save_special_subsidy(
          by: admin_user, name: "Cumpleaños", subsidy_percentage: 10, applies_to_all: true, consumer_ids: [],
          condition: { type: "birthday", limit: 1, validity_amount: 1, validity_unit: "weeks" }
        )
      end
    end

    it "permite modificarlo" do
      visit admin_benefit_configurations_path

      click_button "Editar «Cumpleaños»"

      within("[role=dialog]") do
        expect(page).to have_field("Nombre del subsidio", with: "Cumpleaños")
        expect(page).to have_content("Comienza automáticamente en la fecha de cumpleaños.")

        fill_in "% de descuento", with: "30"
        click_button "Modificar"
      end

      expect(page).to have_content("30%")
      expect(special.reload.subsidy_percentage).to eq(30)
      expect(special.benefit_configuration_changes.map(&:action)).to eq(%w[created updated])
    end

    it "pide confirmación y lo desactiva al eliminarlo" do
      visit admin_benefit_configurations_path

      click_button "Eliminar «Cumpleaños»"
      within("[role=dialog]") { click_button "Eliminar" }

      expect(page).to have_content("No hay subsidios especiales")
      expect(special.reload.deactivated_at).to be_present
    end
  end
end
