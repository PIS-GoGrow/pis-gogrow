# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configuración de beneficio general por RRHH", type: :system do
  fixtures :users, :companies, :admins, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }

  before do
    sign_in admin_user, role: :admin
  end

  def open_editor
    click_button "Editar"
    unless page.has_field?("subsidy_percentage", wait: 2)
      click_button "Editar"
    end
  end

  it "permite a RRHH ver el subsidio actual, editarlo y programar un nuevo cambio" do
    visit admin_benefit_configurations_path

    expect(page).to have_content("Subsidios")
    expect(page).to have_content("50%")

    open_editor

    fill_in "subsidy_percentage", with: "65"
    fill_in "max_voucher_price", with: "250"
    fill_in "monthly_voucher_limit", with: "15"

    click_button "Programar Subsidio"

    date = Calendar.new.configurable_month.strftime("%d/%m/%y")
    expect(page).to have_content("Hay un cambio programado para el " + date, wait: 30)

    new_config = BenefitConfiguration.joins(:benefit_rules)
                                     .where(benefit_rules: { effective_from: Date.current.next_month.beginning_of_month })
                                     .last
    expect(new_config).to be_present
    expect(new_config.subsidy_percentage).to eq(65)
    expect(new_config.benefit_rules.first.max_price).to eq(250)
    expect(new_config.benefit_rules.first.limit).to eq(15)
  end

  it "muestra un aviso de conflicto y permite reemplazar cuando ya existe un cambio programado" do
    # Precondición: ya existe un cambio programado para el próximo período
    BenefitConfiguration.new_base_subsidy(
      company: admin_user.admin.company,
      created_by: admin_user,
      subsidy_percentage: 60,
      max_price: 200,
      limit: 20,
      effective_from: Date.current.next_month.beginning_of_month
    ).save!

    visit admin_benefit_configurations_path

    open_editor

    fill_in "subsidy_percentage", with: "70"
    click_button "Programar Subsidio"

    date = Calendar.new.configurable_month.strftime("%d/%m/%y")
    expect(page).to have_content("Ya hay un cambio programado para el " + date, wait: 30)

    click_button "Reemplazar por este"

    expect(page).to have_no_button("Reemplazar por este")
    expect(page).to have_button("Editar", wait: 30)

    replaced_config = BenefitConfiguration.joins(:benefit_rules)
                                          .where(benefit_rules: { effective_from: Date.current.next_month.beginning_of_month })
                                          .last
    expect(replaced_config).to be_present
    expect(replaced_config.subsidy_percentage).to eq(70)
  end
end
