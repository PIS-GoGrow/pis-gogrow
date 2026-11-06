# frozen_string_literal: true

require "rails_helper"

# Historia IBP-094 (US-P35): "Como PROVEEDOR, quiero iniciar sesión y ver la
# pantalla de inicio desde la aplicación MOBILE."
# CA1: entrar desde la bienvenida con email y contraseña en el celular.
# CA2: recuperar la contraseña con el código del correo en el celular.
# CA3: ver en el celular el resumen del inicio y abrir los hallazgos.
RSpec.describe "Login e inicio del proveedor en el celular", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:provider_user) { users(:provider_user) }
  let(:new_password) { "Nueva-Clave-2026-ok!" }

  def mobile_nav
    find("nav[aria-label='Navegación del proveedor']")
  end

  before { page.current_window.resize_to(375, 812) }

  # CA1
  it "entra desde la bienvenida con el botón al pie de la pantalla" do
    visit_hydrated provider_home_path

    expect(page).to have_content("Pedidos, menú y cobros, en un solo lugar")
    button_bottom = page.evaluate_script(<<~JS)
      document.querySelector("a[href='#{provider_sign_in_path}']").getBoundingClientRect().bottom
    JS
    expect(button_bottom).to be > page.evaluate_script("window.innerHeight") - 40

    click_link "Continuar con Email"
    expect(page).to have_content("¡Bienvenido de nuevo!")
    expect(page).to have_button("Iniciar sesión", disabled: true)

    fill_in "email", with: provider_user.email
    fill_in "password", with: "Secret1*3*5*"
    click_button "Iniciar sesión"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(page).to have_content("Hola, #{provider_user.name}")
    within(mobile_nav) { expect(page).to have_css("a[aria-current=page]", text: "Inicio") }
  end

  # CA2
  it "recupera la contraseña con el código y entra al inicio" do
    visit_hydrated provider_sign_in_path

    click_button "¿Olvidaste tu contraseña?"
    within("[role=dialog]") do
      fill_in "forgot_email", with: provider_user.email
      click_button "Enviar código"
    end

    expect(page).to have_content("Revisá tu email")
    expect(page).to have_button("Volver a mandar código en 5:00", disabled: true).or have_button(/Volver a mandar código en 4:5\d/, disabled: true)

    code = OtpCode.find_by!(user: provider_user, purpose: :password_reset).code
    find("input[name=code]").send_keys(code)
    click_button "Verificar"

    expect(page).to have_content("Nueva Contraseña")
    fill_in "password", with: new_password
    fill_in "password_confirmation", with: new_password
    click_button "Confirmar nueva contraseña"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(provider_user.reload.authenticate(new_password)).to be_truthy
  end

  # CA3
  it "muestra el resumen del día y abre los hallazgos del mes" do
    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(I18n.l(Date.current, format: "%A %-d de %B").capitalize)
    %w[Confirmados Pendientes].each { |label| expect(page).to have_content(label) }
    expect(page).to have_link("Ver pedidos")
    expect(page).to have_content("Resumen de cobros")

    click_link "Hallazgos del mes"

    expect(page).to have_current_path(provider_insights_path)
    expect(page).to have_content("Platos más pedidos")
    expect(page).to have_content("Mejor valorados")

    click_link "Volver al inicio"
    expect(page).to have_current_path(provider_dashboard_path)
  end
end
