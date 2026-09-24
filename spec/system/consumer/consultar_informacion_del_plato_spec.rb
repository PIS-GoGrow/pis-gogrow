# frozen_string_literal: true

require "rails_helper"

# Historia: "Como EMPLEADO, quiero consultar la información relevante de cada
# plato, para tomar una decisión informada."
#
# El detalle del plato no tiene ruta propia: es una vista del dashboard que se
# abre al tocar un plato de la lista. Por eso el límite de permisos no se
# repite acá — es el mismo /dashboard que ya cubre
# consultar_menu_por_fecha_spec.rb, y no hay endpoint aparte al que un rol
# equivocado pueda llegar de forma directa.
#
# TODO(integración): falta corregir el bloque de opiniones antes de poder
# testear qué ve el empleado cuando un plato no tiene reseñas. Hoy la pantalla
# fabrica una reseña de ejemplo, un puntaje 4.8, un autor y una fecha que no
# salen de ningún dato. Historia, criterio 3: "si un dato opcional no fue
# informado, la interfaz no muestra información engañosa ni valores
# inventados". Registrado como defecto, no omitido.
#
# TODO(integración): falta que el cupo subsidiado se cuente contra la fecha de
# entrega antes de poder testear el criterio 2 para los días de la semana que
# caen en el mes siguiente. Hoy el dashboard publica un único cupo mensual,
# calculado sobre el mes en curso, y se lo aplica a todos los días del strip.
# Historia, criterio 2: "el precio del plato, el descuento y la disponibilidad
# mostrados corresponden a la fecha seleccionada".
RSpec.describe "Consultar la información de un plato" do
  fixtures :users, :consumers, :companies, :providers, :menus, :reviews

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:wednesday) { monday + 2 }

  before do
    Order.delete_all
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

  def pick_day(date)
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{date.day}\b/).click }
  end

  def open_dish(menu)
    click_on "Agregar #{menu.name}"
  end

  # Criterio 1
  it "shows every relevant piece of information of the dish" do
    publish(menus(:sorrentinos), monday)
    sign_in users(:one)

    visit dashboard_path
    open_dish(menus(:sorrentinos))

    expect(page).to have_css("h1", text: "Sorrentinos artesanales")
    expect(page).to have_content(users(:other_provider_user).name)
    expect(page).to have_content("Pasta rellena a elección")
    expect(page).to have_content("$320")
    expect(page).to have_content("Mi plato fijo de los miércoles")
  end

  # Criterio 2: el mismo plato, publicado dos días con cupo distinto. Lo que el
  # detalle muestra tiene que seguir al día elegido, no al plato.
  it "shows the availability of the date picked, not of the dish" do
    publish(menus(:sorrentinos), monday, amount: 5)
    publish(menus(:sorrentinos), wednesday, amount: 1)
    sign_in users(:one)

    visit dashboard_path
    open_dish(menus(:sorrentinos))
    expect(page).to have_button("Agregar uno", disabled: false)

    click_on "Volver"
    pick_day(wednesday)
    open_dish(menus(:sorrentinos))

    # Con una sola unidad publicada para el miércoles, no se puede subir la
    # cantidad: el cupo del lunes no se arrastra.
    expect(page).to have_button("Agregar uno", disabled: true)
  end

  it "shows the discount of the employee benefit on the dish price" do
    publish(menus(:sorrentinos), monday)
    Benefit.create!(consumer: consumers(:one), amount: 20, percentage: 50, due_date: 1.month.from_now)
    sign_in users(:one)

    visit dashboard_path
    open_dish(menus(:sorrentinos))

    expect(page).to have_content("Beneficio GoGrow (50%)")
    expect(page).to have_content("Monto a pagar")
    expect(page).to have_content("$160")
  end

  # Criterio 3
  it "does not fill in a description the dish never had" do
    menus(:milanesa).update!(description: nil)
    publish(menus(:milanesa), monday)
    sign_in users(:one)

    visit dashboard_path
    open_dish(menus(:milanesa))

    expect(page).to have_css("h1", text: "Milanesa con papas fritas")
    expect(page).to have_no_content("Opción de carne o pollo")
    expect(page).to have_no_content("null")
    expect(page).to have_no_content("undefined")
  end

  # Criterio 4
  it "reflects what changed in the menu after a reload" do
    schedule = publish(menus(:milanesa), monday, amount: 2)
    sign_in users(:one)

    visit dashboard_path
    expect(page).to have_button("Agregar Milanesa con papas fritas", disabled: false)
    expect(page).to have_no_content("Agotado")

    # Otro empleado se lleva las dos unidades que quedaban.
    order_away(schedule, 2)
    refresh

    expect(page).to have_content("Agotado")
    expect(page).to have_button("Agregar Milanesa con papas fritas", disabled: true)
  end

  it "picks up a dish published after the page was already open" do
    publish(menus(:milanesa), monday)
    sign_in users(:one)

    visit dashboard_path
    expect(page).to have_no_content("Sorrentinos artesanales")

    publish(menus(:sorrentinos), monday)
    refresh

    expect(page).to have_content("Sorrentinos artesanales")
  end
end
