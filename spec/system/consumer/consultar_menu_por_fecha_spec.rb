# frozen_string_literal: true

require "rails_helper"

# Historia IBP-003: "Como EMPLEADO, quiero consultar en un único lugar el menú
# disponible para una fecha, incluyendo las opciones de todos los proveedores,
# para elegir qué comida pedir."
#
# TODO(integración): falta implementar la creación de pedidos (OrdersController y
# SchedulesController están vacíos en esta rama) antes de poder testear que un plato
# agotado efectivamente no puede pedirse. Hoy el criterio 3 solo se puede verificar
# del lado de la vista: badge "Agotado" y botón deshabilitado. Cuando exista el alta
# de pedidos hay que agregar el caso server-side (POST contra un schedule agotado
# tiene que ser rechazado, no solo escondido en la UI).
# Historia: "El empleado consulta el menú de una fecha y elige qué comida pedir".
#
# TODO(integración): falta implementar el concepto de proveedor "habilitado" — el
# modelo Provider no tiene ningún flag de habilitación y Consumer::MenusController
# lista Provider.all. Hasta que exista, no se puede testear que un proveedor
# deshabilitado quede fuera del listado.
# Historia: "...incluyendo las opciones de todos los proveedores habilitados".
RSpec.describe "Consultar el menú por fecha" do
  fixtures :users

  # Un miércoles siempre futuro: cae dentro del strip lunes–viernes que arma WeekNav
  # y evita que la vista lo trate como fecha pasada (isPast se calcula en el browser,
  # así que travel_to no sirve acá).
  let(:fecha) { Date.current.next_occurring(:wednesday) }
  let(:empleado) { users(:empleado) }

  let!(:consumer) { create(:consumer, user: empleado) }
  let(:sabores) { create(:provider, user: users(:proveedor_sabores)) }
  let(:verde) { create(:provider, user: users(:proveedor_verde)) }

  def publicar(provider, date:, name:, amount: 10)
    create(:schedule, date: date, amount: amount, menu: create(:menu, name: name, provider: provider))
  end

  def elegir_dia(date)
    find('[role="radio"]', text: /\b#{date.day}\b/).click
  end

  # El botón de pedido no tiene texto ni aria-label, así que no hay forma de
  # encontrarlo por rol o etiqueta: hay que bajar a la tarjeta que lo contiene.
  # Ver DEFECT-boton-pedir-sin-handler-20-09-2026.md.
  def boton_de_pedido_de(nombre_del_plato)
    find("p", text: nombre_del_plato).ancestor("div.rounded-xl").find("button")
  end

  # AC1
  it "muestra en una misma pantalla los platos de todos los proveedores de la fecha" do
    publicar(sabores, date: fecha, name: "Milanesa con puré")
    publicar(verde, date: fecha, name: "Tarta de zapallo")

    sign_in empleado
    visit "/menus?date=#{fecha}"

    expect(page).to have_content("Milanesa con puré")
    expect(page).to have_content("Tarta de zapallo")
    expect(page).to have_content("Sabores del Sur")
    expect(page).to have_content("Cocina Verde")
  end

  # AC2 — el cambio de día pasa por el selector, no por la URL.
  it "al elegir otro día del selector muestra solo los platos de ese día" do
    publicar(sabores, date: fecha, name: "Plato del miércoles")
    publicar(verde, date: fecha + 1, name: "Plato del jueves")

    sign_in empleado
    visit "/menus?date=#{fecha}"

    expect(page).to have_content("Plato del miércoles")
    expect(page).to have_no_content("Plato del jueves")

    elegir_dia(fecha + 1)

    expect(page).to have_content("Plato del jueves")
    expect(page).to have_no_content("Plato del miércoles")
  end

  # AC3 — identificado como agotado y sin posibilidad de pedirlo desde la pantalla.
  it "identifica el plato agotado y deja su botón de pedido deshabilitado" do
    publicar(sabores, date: fecha, name: "Guiso agotado", amount: 0)
    publicar(verde, date: fecha, name: "Ensalada disponible", amount: 5)

    sign_in empleado
    visit "/menus?date=#{fecha}"

    expect(page).to have_content("Agotado")
    expect(boton_de_pedido_de("Guiso agotado")).to be_disabled
    expect(boton_de_pedido_de("Ensalada disponible")).not_to be_disabled
  end

  # AC4
  it "muestra un estado vacío informativo cuando no hay menú publicado para la fecha" do
    publicar(sabores, date: fecha + 1, name: "Plato de otro día")

    sign_in empleado
    visit "/menus?date=#{fecha}"

    expect(page).to have_content("Menú no disponible")
    expect(page).to have_content("Todavía no hay viandas publicadas para este día")
    expect(page).to have_no_content("Plato de otro día")
  end

  # Transversal — persistencia y consistencia entre vistas.
  it "mantiene lo publicado tras recargar y tras cerrar y volver a iniciar sesión" do
    publicar(sabores, date: fecha, name: "Milanesa con puré")

    sign_in empleado
    visit "/menus?date=#{fecha}"
    expect(page).to have_content("Milanesa con puré")

    page.refresh
    expect(page).to have_content("Milanesa con puré")

    sign_out
    visit "/menus?date=#{fecha}"
    expect(page).to have_current_path("/sign_in", ignore_query: true)

    sign_in empleado
    visit "/menus?date=#{fecha}"
    expect(page).to have_content("Milanesa con puré")
  end

  # Transversal — permisos: verificado server-side en spec/requests/consumer/menus_spec.rb.
  # Acá se comprueba que además no quede una pantalla a medias renderizada en el browser.
  it "no muestra la pantalla a un visitante sin sesión" do
    publicar(sabores, date: fecha, name: "Milanesa con puré")

    visit "/menus?date=#{fecha}"

    expect(page).to have_current_path("/sign_in", ignore_query: true)
    expect(page).to have_no_content("Milanesa con puré")
  end
end
