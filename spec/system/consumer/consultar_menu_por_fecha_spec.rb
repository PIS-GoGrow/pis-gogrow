# frozen_string_literal: true

require "rails_helper"

# Historia IBP-003: "Como EMPLEADO, quiero consultar en un único lugar el menú
# disponible para una fecha, incluyendo las opciones de todos los proveedores,
# para elegir qué comida pedir."
#
# La pantalla es /dashboard: es a donde el sidebar del empleado manda "Menú del
# día". /menus implementa la misma historia pero ningún enlace de la app la
# alcanza; no se cubre acá a propósito (ver los defectos del repo de testing).
#
# TODO(integración): falta implementar el concepto de "proveedor habilitado"
# antes de poder testear el criterio 1 completo ("los platos publicados por
# todos los proveedores habilitados"). Provider no tiene ningún flag de
# habilitación y el dashboard lista lo publicado por todos sin distinguir.
# Historia: "consultar el menú disponible para una fecha, con las opciones de
# todos los proveedores habilitados".
#
# TODO(integración): falta implementar la navegación a otras semanas antes de
# poder testear "seleccionar una fecha" fuera de la semana en curso. El
# controller arma siempre Date.current.beginning_of_week(:monday)..+4 y la
# pantalla monta el selector con showArrows={false}, así que hoy la fecha
# seleccionable son cinco días fijos. Historia: "el empleado puede seleccionar
# una fecha y visualizar los platos publicados para ella".
RSpec.describe "Consultar el menú disponible por fecha" do
  fixtures :users, :consumers, :companies, :providers, :menus

  # Se viaja a un lunes futuro por dos razones: la semana que arma el server
  # queda completa y estable, y todos sus días caen por delante del reloj del
  # browser, que es con el que la pantalla decide si un día ya pasó. No se puede
  # resolver del lado de Ruby: isPast se calcula en el cliente.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:wednesday) { monday + 2 }

  before do
    # Los fixtures publican con fechas relativas a la fecha real; bajo travel_to
    # caen fuera de la semana mostrada. Se limpia para que cada ejemplo declare
    # exactamente lo que espera ver en pantalla.
    Order.destroy_all
    Schedule.delete_all
  end

  def publish(menu, date, amount: 5)
    Schedule.create!(menu:, date:, amount:)
  end

  def order_away(schedule, quantity)
    Order.create!(
      consumer: consumers(:other),
      schedule:,
      amount: quantity,
      price: schedule.menu.price * quantity,
      address: consumers(:other).company.address,
      delivery_method: :office
    )
  end

  # El selector de días no expone la fecha en el DOM: cada día es un radio con
  # su número visible, que es lo que ve el empleado.
  def pick_day(date)
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{date.day}\b/).click }
  end

  # Criterio 1
  it "shows dishes from every provider for the same date in one place" do
    publish(menus(:milanesa), monday)
    publish(menus(:sorrentinos), monday)
    sign_in users(:one)

    visit dashboard_path

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_content("Sorrentinos artesanales")
    expect(page).to have_content(users(:provider_user).name)
    expect(page).to have_content(users(:other_provider_user).name)
  end

  # Criterio 2 — lo que un request spec no puede ver: el día se elige en el
  # browser y la lista se recorta contra esa selección, sin volver al server.
  it "shows only the dishes of the day picked in the selector" do
    publish(menus(:milanesa), monday)
    publish(menus(:sorrentinos), wednesday)
    sign_in users(:one)

    visit dashboard_path

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_no_content("Sorrentinos artesanales")

    pick_day(wednesday)

    expect(page).to have_content("Sorrentinos artesanales")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end

  # Criterio 3
  it "marks the sold out dish and leaves only the available one orderable" do
    sold_out = publish(menus(:milanesa), monday, amount: 2)
    publish(menus(:sorrentinos), monday, amount: 2)
    order_away(sold_out, 2)
    sign_in users(:one)

    visit dashboard_path

    expect(page).to have_content("Agotado")
    expect(page).to have_button("Agregar Milanesa con papas fritas", disabled: true)
    expect(page).to have_button("Agregar Sorrentinos artesanales", disabled: false)
  end

  # No hay un ejemplo que clickee el plato agotado: Selenium se niega a
  # interactuar con un control deshabilitado, así que el click no es
  # simulable. La otra mitad del criterio —que el server tampoco lo acepte—
  # se cubre en spec/requests/orders_spec.rb, que es donde vive la guarda real
  # (Order.reserve), no en la pantalla.

  # Criterio 4
  it "shows an informative empty state for a day with nothing published" do
    publish(menus(:milanesa), monday)
    sign_in users(:one)

    visit dashboard_path
    pick_day(wednesday)

    expect(page).to have_content("Menú no disponible")
    expect(page).to have_content("Todavía no hay viandas publicadas para este día")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end

  # Transversal — persistencia y consistencia entre vistas.
  it "keeps what is published across a reload and a sign out and in again" do
    publish(menus(:milanesa), monday)
    sign_in users(:one)

    visit dashboard_path
    expect(page).to have_content("Milanesa con papas fritas")

    refresh
    expect(page).to have_content("Milanesa con papas fritas")

    sign_out
    visit dashboard_path
    expect(page).to have_no_content("Milanesa con papas fritas")

    sign_in users(:one)
    visit dashboard_path
    expect(page).to have_content("Milanesa con papas fritas")
  end

  # Transversal — permisos: la pantalla no se alcanza sin sesión, y no se filtra
  # nada de su contenido al browser.
  it "keeps a visitor with no session out of the screen" do
    publish(menus(:milanesa), monday)

    visit dashboard_path

    expect(page).to have_current_path(sign_in_path)
    expect(page).to have_no_content("Milanesa con papas fritas")
    expect(page).to have_no_content("Menú semanal")
  end
end
