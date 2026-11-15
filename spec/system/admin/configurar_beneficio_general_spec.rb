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

    date = DateFormat.long(Calendar.new.configurable_month, inline: true)
    expect(page).to have_content("Hay un cambio programado para el " + date, wait: 30)

    new_config = BenefitConfiguration.joins(:benefit_rules)
                                     .where(benefit_rules: { effective_from: Calendar.new.configurable_month })
                                     .last
    expect(new_config).to be_present
    expect(new_config).to be_applies_to_all
    expect(new_config.subsidy_percentage).to eq(65)
    expect(new_config.benefit_rules.first.max_price).to eq(250)
    expect(new_config.benefit_rules.first.limit).to eq(15)
  end

  it "programa un subsidio base que aplica a toda la empresa y cubre a nuevos empleados" do
    visit admin_benefit_configurations_path

    open_editor

    fill_in "subsidy_percentage", with: "60"
    fill_in "max_voucher_price", with: "300"
    fill_in "monthly_voucher_limit", with: "20"

    click_button "Programar Subsidio"

    date = DateFormat.long(Calendar.new.configurable_month, inline: true)
    expect(page).to have_content("Hay un cambio programado para el " + date, wait: 30)

    config = BenefitConfiguration.joins(:benefit_rules)
                                 .where(benefit_rules: { effective_from: Calendar.new.configurable_month })
                                 .last
    expect(config).to be_applies_to_all

    new_user = User.create!(name: "Lucía", email: "lucia@gogrow.com", password: "password123456")
    new_consumer = Consumer.create!(
      user: new_user,
      company: admin_user.admin.company,
      address: "Canelones 1234",
      birthday: Date.new(1995, 8, 20),
      onboarding_date: Date.current
    )

    travel_to Calendar.new.configurable_month do
      BenefitAssignationJob.perform_now
    end

    expect(new_consumer.reload.benefits.where(benefit_configuration: config)).to be_present
  end

  it "muestra un aviso de conflicto y permite reemplazar cuando ya existe un cambio programado" do
    # Precondición: ya existe un cambio programado para el próximo período
    BenefitConfiguration.new_base_subsidy(
      company: admin_user.admin.company,
      created_by: admin_user,
      subsidy_percentage: 60,
      max_price: 200,
      limit: 20,
      effective_from: Calendar.new.configurable_month
    ).save!

    visit admin_benefit_configurations_path

    open_editor

    fill_in "subsidy_percentage", with: "70"
    click_button "Programar Subsidio"

    date = DateFormat.long(Calendar.new.configurable_month, inline: true)
    expect(page).to have_content("Ya hay un cambio programado para el " + date, wait: 30)

    click_button "Reemplazar por este"

    expect(page).to have_no_button("Reemplazar por este")
    expect(page).to have_content("Hay un cambio programado para el " + date, wait: 30)

    replaced_config = BenefitConfiguration.joins(:benefit_rules)
                                          .where(benefit_rules: { effective_from: Calendar.new.configurable_month })
                                          .last
    expect(replaced_config).to be_present
    expect(replaced_config.subsidy_percentage).to eq(70)
  end

  it "muestra error en español junto al campo cuando el porcentaje está fuera de rango" do
    visit admin_benefit_configurations_path

    open_editor

    fill_in "subsidy_percentage", with: "150"
    click_button "Programar Subsidio"

    expect(page).to have_content("debe ser menor que o igual a 100")
  end

  it "configura el campo de precio por vianda con atributos enteros y muestra la unidad viandas" do
    visit admin_benefit_configurations_path

    open_editor

    input = find_field("max_voucher_price")
    expect(input[:step]).to eq("1")
    expect(input[:min]).to eq("1")
    expect(input[:inputmode]).to eq("numeric")

    expect(page).to have_content("viandas")
  end
end
