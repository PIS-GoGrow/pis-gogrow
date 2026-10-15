# frozen_string_literal: true

require "rails_helper"

# Historia IBP-048: "Como PROVEEDOR, quiero consultar y configurar los datos y
# preferencias de notificación de mi perfil para gestionar mi cuenta."
#
# Criterio 1 (datos de cobro), criterio 3 (validación y persistencia) y criterio 4
# (auditoría y restricción de rol) sobre /provider/payment_details.
#
# La validación por campo y los valores límite del formato de tax_id también están
# cubiertos a nivel request en spec/requests/provider/payment_details_spec.rb; acá
# se ejercita el recorrido real del formulario en el browser.
RSpec.describe "Configurar los datos de cobro del proveedor" do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }

  # El Select de shadcn es un botón de radix: se abre con un clic y las opciones
  # aparecen como [role=option]. Mismo patrón que OrderDeadlineHelpers.
  def choose_account_type(label)
    find_by_id("bank_account_type").click
    find("[role=option]", exact_text: label).click
  end

  def fill_valid_details(tax_id: "212345670012", number: "001234567-00001")
    fill_in "bank_name", with: "BROU"
    choose_account_type "Caja de ahorro"
    fill_in "bank_account_number", with: number
    fill_in "bank_account_holder", with: "Tu Vianda SRL"
    fill_in "tax_id", with: tax_id
  end

  it "guarda los datos de cobro y persisten al volver a iniciar sesión" do
    sign_in provider_user, role: :provider
    visit provider_account_path
    click_link "Datos de cobro"

    expect(page).to have_current_path(provider_payment_details_path)

    fill_valid_details
    click_on "Guardar"

    expect(page).to have_content("Datos de cobro actualizados")
    expect(provider.reload).to have_attributes(
      bank_name: "BROU",
      bank_account_type: "savings",
      bank_account_number: "001234567-00001",
      bank_account_holder: "Tu Vianda SRL",
      tax_id: "212345670012"
    )

    sign_out
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    expect(page).to have_field("bank_name", with: "BROU")
    expect(page).to have_field("bank_account_number", with: "001234567-00001")
    expect(page).to have_field("bank_account_holder", with: "Tu Vianda SRL")
    expect(page).to have_field("tax_id", with: "212345670012")
    expect(page).to have_content("Caja de ahorro")
  end

  it "acepta el límite inferior de CI (7 dígitos) y cuenta corriente" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_in "bank_name", with: "Itaú"
    choose_account_type "Cuenta corriente"
    fill_in "bank_account_number", with: "12345678"
    fill_in "bank_account_holder", with: "Tu Vianda SRL"
    fill_in "tax_id", with: "1234567"
    click_on "Guardar"

    expect(page).to have_content("Datos de cobro actualizados")
    expect(provider.reload).to have_attributes(bank_account_type: "checking", tax_id: "1234567")
  end

  it "rechaza un RUT o CI con una cantidad de dígitos inválida" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_valid_details tax_id: "123456789"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "no es válido")
    expect(provider.reload).to have_attributes(bank_name: nil, tax_id: nil)
  end

  it "rechaza un número de cuenta con letras" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_valid_details number: "ABC123"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "no es válido")
    expect(provider.reload).to have_attributes(bank_account_number: nil)
  end

  it "exige todos los datos y no guarda ninguno" do
    sign_in provider_user, role: :provider
    visit provider_payment_details_path

    fill_in "bank_name", with: "BROU"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "no puede estar en blanco")
    expect(provider.reload).to have_attributes(
      bank_name: nil,
      bank_account_type: nil,
      bank_account_number: nil,
      bank_account_holder: nil,
      tax_id: nil
    )
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
    expect(log.changeset["tax_id"]).to eq([ nil, "212345670012" ])
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
