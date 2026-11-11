# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configurar los datos de cobro del proveedor" do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }

  before do
    provider.update!(bank_name: nil, bank_account_details: nil, beneficiary: nil)
  end

  def choose_bank(label)
    find_by_id("bank_name").click
    find("[role=option]", exact_text: label).click
    expect(page).not_to have_css("[role=option]", visible: true, wait: 5)
  end

  def fill_valid_details(details: "Cuenta: 001234567-00001\nMoneda: UYU")
    choose_bank "BROU"
    fill_in "bank_account_details", with: details
    fill_in "beneficiary", with: "Tu Vianda SRL"
  end

  it "registra los tres datos y luego los muestra en modo consulta" do
    sign_in provider_user, role: :provider
    visit provider_account_path
    click_link "Datos de cobro"

    expect(page).to have_current_path(provider_payment_details_path)
    expect(page).to have_field("bank_account_details")

    fill_valid_details
    click_on "Guardar"

    expect(page).to have_content("Datos de cobro actualizados")
    expect(page).to have_content("BROU")
    expect(page).to have_content("Nº de cuenta: 001234567-00001")
    expect(page).to have_no_content("Moneda: UYU")
    expect(page).to have_content("Tu Vianda SRL")
    expect(page).to have_link("Editar")
    expect(page).to have_no_field("bank_account_details")
    expect(provider.reload).to have_attributes(
      bank_name: "BROU",
      bank_account_details: "Cuenta: 001234567-00001\nMoneda: UYU",
      beneficiary: "Tu Vianda SRL"
    )

    sign_out
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    expect(page).to have_link("Editar")
    expect(page).to have_no_field("bank_account_details")
  end

  it "edita los datos existentes y conserva los saltos de línea" do
    provider.update!(
      bank_name: "Santander",
      bank_account_details: "Cuenta: 1150260\nMoneda: UYU",
      beneficiary: "Tu Viandita S.A."
    )
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    click_link "Editar"
    expect(find_by_id("bank_name")).to have_text("Santander")
    fill_in "bank_account_details", with: "Cuenta: UY00 0000 1150 260\nSucursal: 70 - Golf"
    fill_in "beneficiary", with: "Tu Viandita SRL"
    click_on "Guardar"

    expect(page).to have_content("Nº de cuenta: UY00 0000 1150 260")
    expect(page).to have_content("Sucursal: 70 - Golf")
    expect(provider.reload.bank_account_details).to eq("Cuenta: UY00 0000 1150 260\nSucursal: 70 - Golf")
  end

  it "cancela la edición sin modificar los datos" do
    provider.update!(
      bank_name: "Santander",
      bank_account_details: "Cuenta: 1150260",
      beneficiary: "Tu Viandita S.A."
    )
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    click_link "Editar"
    fill_in "bank_account_details", with: "Cambio sin guardar"
    click_link "Cancelar"

    expect(page).to have_content("Nº de cuenta: 1150260")
    expect(page).to have_no_content("Cambio sin guardar")
    expect(provider.reload.bank_account_details).to eq("Cuenta: 1150260")
  end

  it "muestra errores específicos y conserva los valores ingresados" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    choose_bank "BROU"
    fill_in "bank_account_details", with: "Cuenta ABC\nMoneda: UYU"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "no puede estar en blanco")
    expect(page).to have_field("bank_account_details", with: "Cuenta ABC\nMoneda: UYU")
    expect(provider.reload).to have_attributes(bank_name: nil, bank_account_details: nil, beneficiary: nil)
    expect(provider.audit_logs).to be_empty
  end

  it "registra quién hizo el cambio y los valores anterior y nuevo" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_valid_details
    click_on "Guardar"

    expect(page).to have_content("Datos de cobro actualizados")
    log = provider.reload.audit_logs.sole
    expect(log.user).to eq(provider_user)
    expect(log.changeset["bank_name"]).to eq([ nil, "BROU" ])
    expect(log.changeset["bank_account_details"]).to eq([ nil, "Cuenta: 001234567-00001\nMoneda: UYU" ])
  end

  it "no modifica los datos de cobro de otro proveedor" do
    other_provider = providers(:endulzate)
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_valid_details
    click_on "Guardar"

    expect(page).to have_content("Datos de cobro actualizados")
    expect(provider.reload.bank_name).to eq("BROU")
    expect(other_provider.reload.bank_name).to be_nil
    expect(other_provider.audit_logs).to be_empty
  end

  it "no deja entrar a un consumidor ni a RRHH" do
    sign_in users(:one), role: :consumer
    visit provider_payment_details_path
    expect(page).to have_no_current_path(provider_payment_details_path)

    sign_out
    sign_in users(:admin), role: :admin
    visit provider_payment_details_path
    expect(page).to have_no_current_path(provider_payment_details_path)
  end

  it "no deja entrar sin sesión" do
    visit provider_payment_details_path

    expect(page).to have_current_path(provider_sign_in_path)
  end
end
