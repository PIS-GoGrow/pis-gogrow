# frozen_string_literal: true

require "rails_helper"

# IBP-022 — Como EMPLEADO, quiero seleccionar las opciones de personalización que el
# plato admita al momento de pedir, para recibir la vianda según mi preferencia.
#
# Criterio 1: "El empleado solo puede seleccionar opciones customizables agregadas
# al plato por el proveedor."
# Criterio 2: "No se podrá confirmar el pedido si faltan rellenar campos obligatorios."
# Criterio 3: "Se acepta un mensaje de aclaraciones (opcional) de máximo 400
# caracteres."
#
# El máximo de 400 caracteres del criterio 3 NO está implementado y por indicación
# de quien pidió esta corrida no se cubre: la pantalla del plato limita a 140
# (dish-detail.tsx) y el diálogo de modificar el pedido no limita nada, sin
# validación en el servidor. Registrado en
# docs/reports/defects/DEFECT-limite-400-caracteres-claraciones-04-10-2026.md
#
# Los grupos se cargan por modelo y no desde la pantalla del proveedor: esa
# pantalla (Provider::MenusController + new-menu-form.tsx) tiene specs de request
# pero ninguno de sistema, y es otra historia. Acá importa lo que el empleado ve y
# puede elegir.
RSpec.describe "Seleccionar la personalización del plato", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :menu_option_groups

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:sorrentinos) { menus(:sorrentinos) }
  let(:milanesa) { menus(:milanesa) }
  let(:salsa) { sorrentinos.option_groups.find_by!(name: "Salsa") }
  let(:relleno) { sorrentinos.option_groups.find_by!(name: "Relleno") }
  let(:extras) { milanesa.option_groups.find_by!(name: "Extras") }
  # Las publicaciones se guardan en un let y no se buscan por plato: schedules.yml
  # ya trae una publicación de sorrentinos para hoy, así que un find_by(menu:)
  # puede devolver la del fixture en vez de la de acá.
  let(:sorrentinos_schedule) { Schedule.create!(menu: sorrentinos, date: monday, amount: 10) }
  let(:milanesa_schedule) { Schedule.create!(menu: milanesa, date: monday, amount: 10) }

  before do
    # Los dos platos se publican el mismo día: el de sorrentinos trae los grupos
    # de los fixtures y el de milanesa uno con límite 2, para poder probar las dos
    # formas de elegir (una sola opción o varias).
    milanesa.option_groups.create!(name: "Extras", options: [ "Papaya", "Arándanos", "Limón" ], limit: 2)
    sorrentinos_schedule
    milanesa_schedule

    sign_in users(:one), role: :consumer
    visit dashboard_path
    calm_animations
  end

  # Las hojas entran deslizándose: en CI el clic caía mientras se movían.
  def calm_animations
    page.execute_script(<<~JS)
      const style = document.createElement("style")
      style.textContent = "*, *::before, *::after { animation: none !important; transition: none !important; }"
      document.head.appendChild(style)
    JS
  end

  def open_dish(menu)
    click_button "Agregar #{menu.name}"
    expect(page).to have_content("Notas para este plato")
  end

  # Cada grupo es una <section> con el título "Elegí tu <nombre>". Buscar por ese
  # título y no por el texto de la opción evita elegir la de otro grupo.
  def pick_option(group_name, option)
    find("section", text: "Elegí tu #{group_name}").find("label", text: option).click
  end

  def checked_option(group_name)
    find("section", text: "Elegí tu #{group_name}")
      .find("label:has([role=radio][aria-checked=true])").text
  end

  def add_to_cart
    click_button "Agregar"
  end

  def open_cart
    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
  end

  def confirm_order
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
  end

  def order_with_selections
    Order.create!(
      consumer: consumers(:one),
      schedule: sorrentinos_schedule,
      amount: 1,
      price: sorrentinos.price,
      discounted_price: sorrentinos.price,
      address: companies(:gogrow).address,
      delivery_method: :office,
      selected_options: [
        { group_id: salsa.id, name: "Salsa", values: [ "Bolognesa" ] },
        { group_id: relleno.id, name: "Relleno", values: [ "Ricota y nuez" ] }
      ]
    )
  end

  def milanesa_order(values)
    Order.create!(
      consumer: consumers(:one),
      schedule: milanesa_schedule,
      amount: 1,
      price: milanesa.price,
      discounted_price: milanesa.price,
      address: companies(:gogrow).address,
      delivery_method: :office,
      selected_options: [ { group_id: extras.id, name: "Extras", values: } ]
    )
  end

  describe "criterio 1: solo ofrece las opciones que el proveedor cargó al plato" do
    it "muestra cada grupo del plato con las opciones que definió el proveedor" do
      open_dish(sorrentinos)

      within("section", text: "Elegí tu Salsa") do
        expect(page).to have_css("[role=radio]", count: 2)
        expect(page).to have_content("Filetto")
        expect(page).to have_content("Bolognesa")
      end
      within("section", text: "Elegí tu Relleno") do
        expect(page).to have_css("[role=radio]", count: 2)
        expect(page).to have_content("Ricota y nuez")
        expect(page).to have_content("Espinaca y queso")
      end
    end

    it "deja elegir una sola opción por grupo" do
      open_dish(sorrentinos)

      pick_option("Salsa", "Filetto")
      pick_option("Salsa", "Bolognesa")

      expect(checked_option("Salsa")).to include("Bolognesa")
      expect(checked_option("Salsa")).to have_no_content("Filetto")
    end

    it "no ofrece opciones de otro plato ni opciones que el proveedor no cargó" do
      open_dish(sorrentinos)

      expect(page).to have_no_content("Elegí tu Extras")
      expect(page).to have_no_content("Papaya")
      expect(page).to have_no_content("Arándanos")
      expect(page).to have_no_content("Limón")

      # El mismo grupo sí existe en el otro plato: no es que el dato no exista.
      click_button "Volver"
      open_dish(milanesa)
      expect(page).to have_content("Elegí tu Extras")
      expect(page).to have_content("Papaya")
    end

    it "deja elegir varias opciones cuando el grupo lo permite y no deja pasar del límite" do
      open_dish(milanesa)

      expect(page).to have_content("Podés elegir hasta 2")
      pick_option("Extras", "Papaya")
      pick_option("Extras", "Arándanos")

      within("section", text: "Elegí tu Extras") do
        expect(find("[role=checkbox][aria-label='Limón']")).to be_disabled
      end

      pick_option("Extras", "Papaya")

      within("section", text: "Elegí tu Extras") do
        expect(find("[role=checkbox][aria-label='Limón']")).not_to be_disabled
      end
    end

    it "guarda lo elegido con el nombre del grupo que definió el proveedor" do
      open_dish(sorrentinos)
      pick_option("Salsa", "Bolognesa")
      pick_option("Relleno", "Espinaca y queso")
      add_to_cart
      open_cart

      expect(page).to have_content("Salsa: Bolognesa")
      expect(page).to have_content("Relleno: Espinaca y queso")

      confirm_order

      expect(Order.last.selected_options).to match_array(
        [
          { "group_id" => salsa.id, "name" => "Salsa", "values" => [ "Bolognesa" ] },
          { "group_id" => relleno.id, "name" => "Relleno", "values" => [ "Espinaca y queso" ] }
        ]
      )
    end
  end

  describe "criterio 2: no se puede confirmar con campos obligatorios sin responder" do
    it "no deja agregar el plato al carrito hasta responder todos los grupos" do
      open_dish(sorrentinos)
      expect(page).to have_button("Agregar", disabled: true)

      pick_option("Salsa", "Bolognesa")
      expect(page).to have_button("Agregar", disabled: true)

      pick_option("Relleno", "Ricota y nuez")
      expect(page).to have_button("Agregar", disabled: false)

      add_to_cart
      open_cart
      confirm_order
      expect(Order.last).to be_present
    end

    it "no deja guardar los cambios de un pedido con un grupo sin responder" do
      order = milanesa_order([ "Papaya" ])
      visit order_path(order)
      calm_animations

      click_button "Editar"
      within("[role=dialog]") do
        expect(page).to have_button("Guardar cambios", disabled: false)

        pick_option("Extras", "Papaya")

        expect(page).to have_button("Guardar cambios", disabled: true)
      end

      expect(order.reload.selected_options.first["values"]).to eq([ "Papaya" ])
    end

    # Un pedido anterior a la funcionalidad no tiene elección guardada, así que el
    # diálogo arranca con los grupos sin responder: tampoco se puede cambiar solo
    # la cantidad hasta elegir la personalización.
    it "exige elegir la personalización de un pedido hecho antes de la funcionalidad" do
      order = order_with_selections
      order.update_column(:selected_options, [])
      visit order_path(order)
      calm_animations

      click_button "Editar"
      within("[role=dialog]") do
        expect(page).to have_button("Guardar cambios", disabled: true)

        pick_option("Salsa", "Bolognesa")
        pick_option("Relleno", "Ricota y nuez")

        expect(page).to have_button("Guardar cambios", disabled: false)
        click_button "Guardar cambios"
      end
      expect(page).to have_no_selector("[role=dialog]")

      expect(order.reload.selected_options.map { it["values"] })
        .to contain_exactly([ "Bolognesa" ], [ "Ricota y nuez" ])
    end

    it "guarda la personalización cambiada del pedido y la muestra en su detalle" do
      order = order_with_selections
      visit order_path(order)
      calm_animations

      click_button "Editar"
      within("[role=dialog]") do
        pick_option("Salsa", "Filetto")
        # El clic y el PATCH son visitas de Inertia: sin esperar a que el radio
        # refleje el cambio, el envío puede llevar la personalización anterior.
        expect(checked_option("Salsa")).to include("Filetto")

        click_button "Guardar cambios"
      end
      expect(page).to have_no_selector("[role=dialog]")

      expect(order.reload.selected_options.map { it["values"] })
        .to contain_exactly([ "Filetto" ], [ "Ricota y nuez" ])
      expect(page).to have_content("Filetto")
      expect(page).to have_no_content("Bolognesa")
    end

    # La pantalla es la primera barrera, pero un POST directo no pasa por ella: el
    # grupo se edita acá en el medio, con el carrito ya armado.
    it "rechaza en el servidor un pedido cuya personalización ya no corresponde al plato" do
      open_dish(sorrentinos)
      pick_option("Salsa", "Bolognesa")
      pick_option("Relleno", "Ricota y nuez")
      add_to_cart
      open_cart

      salsa.update!(options: [ "Filetto" ])

      expect { click_button "Confirmar pedido" }.not_to change(Order, :count)

      expect(page).to have_content("No se pudo procesar el pedido")
      expect(page).to have_content("Elegí las opciones que el plato admite antes de confirmar.")
    end
  end

  describe "criterio 3: campos opcionales y notas" do
    it "permite pedir sin escribir notas" do
      open_dish(sorrentinos)
      pick_option("Salsa", "Filetto")
      pick_option("Relleno", "Ricota y nuez")
      add_to_cart
      open_cart
      confirm_order

      order = Order.last
      expect(order.notes).to be_nil

      visit order_path(order)
      expect(page).to have_content("Sin notas")
    end

    it "guarda las notas como especificaciones del plato y las muestra en el pedido" do
      open_dish(sorrentinos)
      pick_option("Salsa", "Filetto")
      pick_option("Relleno", "Ricota y nuez")
      fill_in "Notas para este plato", with: "Sin sal, por favor"
      add_to_cart
      open_cart

      expect(page).to have_content("Sin sal, por favor")

      confirm_order
      expect(Order.last.notes).to eq("Sin sal, por favor")

      visit order_path(Order.last)
      expect(page).to have_content("Sin sal, por favor")
    end

    it "basta con una sola opción cuando el grupo permite más de una" do
      open_dish(milanesa)
      pick_option("Extras", "Papaya")
      add_to_cart
      open_cart
      confirm_order

      expect(Order.last.selected_options).to eq(
        [ { "group_id" => extras.id, "name" => "Extras", "values" => [ "Papaya" ] } ]
      )
    end
  end

  describe "persistencia y control de acceso" do
    it "la personalización sobrevive a cerrar y volver a abrir sesión" do
      order = order_with_selections
      sign_out

      sign_in users(:one), role: :consumer
      visit order_path(order)

      expect(page).to have_content("Bolognesa")
      expect(page).to have_content("Ricota y nuez")
      # Lo no elegido no se completa con lo que el plato ofrece.
      expect(page).to have_no_content("Filetto")
      expect(page).to have_no_content("Espinaca y queso")
    end

    it "otro empleado no alcanza el pedido con la personalización ajena por URL" do
      order = order_with_selections

      sign_in users(:other_consumer_user), role: :consumer
      visit order_path(order)

      expect(page).to have_no_content("Bolognesa")
      expect(page).to have_no_content("Ricota y nuez")
    end
  end
end
