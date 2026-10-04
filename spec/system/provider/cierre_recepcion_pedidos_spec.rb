# frozen_string_literal: true

require "rails_helper"

# Historia IBP-067: "Como PROVEEDOR, quiero ver cuánto tiempo falta para el cierre
# de recepción de pedidos, para saber a partir de qué momento puedo comenzar a
# preparar."
#
# El criterio 1 se modificó: en vez del tiempo restante, el inicio muestra la hora
# a la que cierra la recepción. El criterio 2 quedó fuera de alcance.
RSpec.describe "Cierre de recepción de pedidos visto por el proveedor" do
  fixtures :users, :providers, :consumers, :companies

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:closed) { "Recepción de pedidos cerrada" }
  let(:all_day) { "Recibiendo pedidos todo el día" }
  # Un lunes futuro: el servidor lo toma como "hoy" y el navegador, que no viaja en
  # el tiempo, no lo marca como fecha pasada.
  let(:monday) { Date.current.next_week(:monday) }

  around do |example|
    travel_to(Time.zone.local(monday.year, monday.month, monday.day, 12, 0)) { example.run }
  end

  before do
    provider.update!(order_deadline: nil)
    providers(:endulzate).update!(order_deadline: nil)
  end

  def open_until(time)
    "Recibiendo pedidos hasta #{time}"
  end

  def visit_dashboard_as_provider
    sign_in provider_user, role: :provider
    visit provider_dashboard_path
  end

  # Criterio 1 (modificado): el proveedor ve hasta qué hora recibe pedidos.
  it "shows until what time orders are received" do
    provider.update!(order_deadline: Time.zone.parse("14:00"))

    visit_dashboard_as_provider

    expect(page).to have_link(open_until("14:00"))
  end

  it "says orders are received all day without a deadline" do
    visit_dashboard_as_provider

    expect(page).to have_link(all_day)
    expect(page).to have_no_content(closed)
  end

  # Criterio 4: el borde. Un minuto antes sigue abierta; justo en la hora y después
  # se muestra cerrada, sin ninguna hora vencida.
  it "keeps receiving orders a minute before the deadline" do
    provider.update!(order_deadline: Time.zone.parse("12:01"))

    visit_dashboard_as_provider

    expect(page).to have_link(open_until("12:01"))
    expect(page).to have_no_content(closed)
  end

  it "says reception is closed right at the deadline" do
    provider.update!(order_deadline: Time.zone.parse("12:00"))

    visit_dashboard_as_provider

    expect(page).to have_link(closed)
    expect(page).to have_no_content(open_until("12:00"))
  end

  it "says reception is closed once the deadline has passed" do
    provider.update!(order_deadline: Time.zone.parse("11:00"))

    visit_dashboard_as_provider

    expect(page).to have_link(closed)
    expect(page).to have_no_content(open_until("11:00"))
  end

  # Criterio 5: el cambio se hace desde el propio inicio, que lleva a la
  # configuración operativa, y al volver se ve la nueva hora.
  it "reopens reception after moving a passed deadline later from the dashboard" do
    provider.update!(order_deadline: Time.zone.parse("11:00"))
    visit_dashboard_as_provider

    click_on closed
    expect(page).to have_current_path(provider_operational_settings_path)
    configure_order_deadline("13:00")

    visit provider_dashboard_path
    expect(page).to have_link(open_until("13:00"))
    expect(page).to have_no_content(closed)
  end

  it "closes reception after moving the deadline earlier than now" do
    provider.update!(order_deadline: Time.zone.parse("13:00"))
    visit_dashboard_as_provider
    expect(page).to have_link(open_until("13:00"))

    configure_order_deadline("11:00")

    visit provider_dashboard_path
    expect(page).to have_link(closed)
  end

  # Persistencia: la hora configurada se sigue viendo tras recargar y con una sesión nueva.
  it "keeps showing the configured deadline after a reload and a new session" do
    visit_dashboard_as_provider
    configure_order_deadline("14:00")

    visit provider_dashboard_path
    page.refresh
    expect(page).to have_link(open_until("14:00"))

    sign_out
    visit_dashboard_as_provider
    expect(page).to have_link(open_until("14:00"))
  end

  # Privacidad entre pares: la hora de un proveedor no se le muestra a otro.
  it "shows each provider only its own deadline" do
    provider.update!(order_deadline: Time.zone.parse("11:00"))

    sign_in users(:other_provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_link(all_day)
    expect(page).to have_no_content(closed)
  end

  # Consistencia entre vistas: cuando el proveedor ve la recepción cerrada, el
  # empleado tampoco puede pedirle para hoy.
  it "matches what the employee sees on today's menu" do
    Schedule.create!(date: monday, amount: 5, menu: Menu.create!(provider:, name: "Milanesa al pan", description: "Plato de prueba", price: 300))
    provider.update!(order_deadline: Time.zone.parse("11:00"))

    visit_dashboard_as_provider
    expect(page).to have_link(closed)
    sign_out

    sign_in users(:one), role: :consumer
    visit dashboard_path
    expect(page).to have_content("Este proveedor ya cerró la recepción de pedidos para hoy.")
    expect(page).to have_button("Agregar Milanesa al pan", disabled: true)
  end
end
