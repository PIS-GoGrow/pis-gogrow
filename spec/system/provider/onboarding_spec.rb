# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recorrido guiado de alta del proveedor (Onboarding)", type: :system do
  fixtures :users, :providers, :companies

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }

  before do
    provider.update!(
      onboarding_completed_at: nil,
      bank_name: nil,
      bank_account_type: nil,
      bank_account_number: nil,
      bank_account_holder: nil,
      tax_id: nil,
      order_deadline: nil
    )
  end

  around do |example|
    Capybara.using_wait_time(60) { example.run }
  end

  def choose_account_type(label)
    trigger = find_by_id("bank_account_type")
    trigger.click

    option = find("[role='option']", exact_text: label, visible: true)
    option.click

    expect(page).not_to have_css("[role='option']", visible: true, wait: 5)
    expect(page).not_to have_css("[data-radix-popper-content-wrapper]", visible: true, wait: 5)

    expect(find_by_id("bank_account_type")).to have_text(label)
  end

  def continue_onboarding
    button = find("button[type='submit'][value='continue']", text: "Continuar", visible: true)
    page.execute_script("arguments[0].scrollIntoView({ behavior: 'instant', block: 'center' });", button)
    button.click
  end

  it "guía al proveedor a través de los 4 pasos, persiste la configuración y desbloquea el panel" do
    sign_in provider_user, role: :provider

    # El guard redirige automáticamente al onboarding
    visit provider_dashboard_path
    expect(page).to have_current_path(provider_onboarding_path)

    # Paso 1: Datos de cobro
    expect(page).to have_content("Paso 1 de 4")
    expect(page).to have_content("Datos de cobro")

    fill_in "bank_name", with: "BROU"
    choose_account_type "Caja de ahorro"
    fill_in "bank_account_number", with: "001234567-00001"
    fill_in "bank_account_holder", with: "Tu Vianda SRL"
    fill_in "tax_id", with: "212345670012"

    continue_onboarding

    # Paso 2: Hora de cierre
    expect(page).to have_content("Paso 2 de 4")
    expect(page).to have_content("Hora de cierre")

    click_button "Agregar hora de cierre"
    find_by_id("order_deadline").click
    find("[role='option']", exact_text: "12:30").click
    click_button "Guardar cambios"
    continue_onboarding

    # Paso 3: Entregas
    expect(page).to have_content("Paso 3 de 4")
    expect(page).to have_content("Entregas")

    # Toggle switch de entregas a domicilio
    find("button[role='switch']").click
    continue_onboarding

    # Paso 4: Notificaciones
    expect(page).to have_content("Paso 4 de 4")
    expect(page).to have_content("Notificaciones")

    click_button "Finalizar"

    # Pantalla final de éxito
    expect(page).to have_content("¡Todo listo!")
    expect(page).to have_content("Tu cuenta ya está configurada")

    click_on "Ir al Inicio"

    # Llega al panel del proveedor y ya no es interceptado por el guard
    expect(page).to have_current_path(provider_dashboard_path)
    expect(page).to have_content("Hola, #{provider_user.name}")

    # Verifica persistencia en base de datos
    provider.reload
    expect(provider).to be_onboarded
    expect(provider.bank_name).to eq("BROU")
    expect(provider.bank_account_type).to eq("savings")
    expect(provider.tax_id).to eq("212345670012")
    expect(provider.order_deadline.strftime("%H:%M")).to eq("12:30")
    expect(provider.home_delivery).to be(false)
    expect(provider.onboarding_completed_at).to be_present

    # Comprueba que la configuración se refleje en las pantallas de cuenta
    visit provider_payment_details_path
    expect(find_field("bank_name").value).to eq("BROU")
    expect(find_field("bank_account_number").value).to eq("001234567-00001")
    expect(find_field("bank_account_holder").value).to eq("Tu Vianda SRL")
    expect(find_field("tax_id").value).to eq("212345670012")

    visit provider_operational_settings_path
    expect(page).to have_button("Hora de cierre", text: "12:30")

    visit provider_deliveries_path
    expect(page).to have_css("#delivery-office[data-state='checked']")
  end

  it "muestra errores de validación si se ingresan datos de cobro inválidos" do
    sign_in provider_user, role: :provider
    visit provider_onboarding_path

    expect(page).to have_content("Paso 1 de 4")

    fill_in "bank_name", with: "BROU"
    choose_account_type "Caja de ahorro"
    fill_in "bank_account_number", with: "001234567-00001"
    fill_in "bank_account_holder", with: "Tu Vianda SRL"
    fill_in "tax_id", with: "12345"

    continue_onboarding

    expect(page).to have_content("Paso 1 de 4")
    expect(provider.reload.bank_name).to be_nil
  end

  it "permite volver al paso anterior y omitir pasos del recorrido" do
    sign_in provider_user, role: :provider
    visit provider_onboarding_path

    expect(page).to have_content("Paso 1 de 4")
    find("button[aria-label='Omitir por ahora']").click

    expect(page).to have_content("Paso 2 de 4")
    expect(provider.reload.bank_name).to be_nil

    find("button[aria-label='Volver al paso anterior']").click
    expect(page).to have_content("Paso 1 de 4")
  end
end
