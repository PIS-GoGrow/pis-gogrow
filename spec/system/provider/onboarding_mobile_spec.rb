# frozen_string_literal: true

require "rails_helper"

# Historia IBP-095 (US-P36): "Como PROVEEDOR, quiero tener un onboarding en la
# aplicación MOBILE donde configurar mi cuenta y notificaciones."
# CA1: posponer la configuración desde la pantalla inicial e ir al inicio.
# CA2: configurar la hora de cierre desde la hoja inferior del celular.
# CA3: terminar con las notificaciones propuestas encendidas y llegar al inicio.
RSpec.describe "Onboarding del proveedor en el celular", type: :system do
  fixtures :users, :providers, :companies

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:notification_configurations) do
    Notification::Configuration.where(configurable: true).for_role(:provider)
  end

  around do |example|
    Capybara.using_wait_time(60) { example.run }
  end

  before do
    provider.update!(onboarding_completed_at: nil, order_deadline: nil, notifications_configured_at: nil)
    page.current_window.resize_to(375, 812)
    sign_in provider_user, role: :provider
  end

  def mobile_nav
    find("nav[aria-label='Navegación del proveedor']")
  end

  # CA1
  it "pospone la configuración y entra al inicio" do
    visit_hydrated provider_dashboard_path

    expect(page).to have_current_path(provider_onboarding_path)
    expect(page).to have_content("¿Configuramos tu cuenta?")
    expect(page).to have_link("Comenzar")

    click_button "Configurar más tarde"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(mobile_nav).to have_link("Inicio")
  end

  # CA2
  it "guarda la hora de cierre desde la hoja inferior" do
    visit_hydrated provider_onboarding_path(step: 2)
    without_animations

    expect(page).to have_content("Paso 2 de 4")
    expect(page).to have_button("Continuar", disabled: true)

    click_button "Agregar hora de cierre"
    within("[role=dialog]") do
      expect(page).to have_content("Agregar Hora de cierre")
      find_by_id("order_deadline").click
    end
    choose_time("10:00")
    click_button "Guardar cambios"

    expect(page).to have_content("¡Hora de cierre guardada!")
    expect(page).to have_content("todos los días a las 10:00")
    click_on "Listo"

    expect(page).to have_button("Continuar", disabled: false)
    expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("10:00")
  end

  # CA3
  it "termina con las notificaciones encendidas y llega al inicio" do
    visit_hydrated provider_onboarding_path(step: 4)

    expect(page).to have_content("Paso 4 de 4")
    expect(page).to have_no_button("Omitir por ahora")
    switches = all("button[role=switch]")
    expect(switches.size).to eq(notification_configurations.count)
    expect(switches.map { it["aria-checked"] }).to all(eq("true"))

    click_button "Finalizar"

    expect(page).to have_content("¡Todo listo!")
    click_on "Ir al Inicio"

    expect(page).to have_current_path(provider_dashboard_path)
    expect(mobile_nav).to have_link("Inicio")
    expect(provider.reload).to be_onboarded
    expect(provider_user.notification_configurations).to match_array(notification_configurations)
  end
end
