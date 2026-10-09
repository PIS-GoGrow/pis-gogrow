# frozen_string_literal: true

require "rails_helper"

# SYS-02: IBP-050, IBP-051, IBP-053, IBP-065, IBP-022, IBP-068, IBP-014, IBP-066,
# IBP-067 e IBP-008. El proveedor publica y edita un menú, el empleado pide y edita
# su pedido, y los datos tienen que coincidir entre la confirmación, el historial
# del empleado y la vista del proveedor.
#
# TODO(integración): falta implementar activar y desactivar una opción de
# personalización sin borrarla antes de poder testear ese caso de IBP-065 CA2.
# Historia: IBP-065 "opciones por plato".
#
# TODO(integración): falta implementar mover un menú publicado a otra fecha antes
# de poder testear esa parte de IBP-051 CA2, y registrar quién y cuándo editó un
# menú publicado para IBP-051 CA5 ("queda registrada"). Historia: IBP-051 "editar
# menús".
#
# TODO(integración): falta implementar cambiar el stock de un plato en un día ya
# publicado antes de poder testear esa parte de IBP-051 CA2. Se hacía desde
# "Editar menú" (update_by_date), que la #101 quitó; falta confirmar con el autor
# si pasa a otra historia. Historia: IBP-051 "editar menús".
#
# TODO(integración): falta implementar el registro de qué campos cambiaron al
# modificar un pedido (hoy solo se guardan modified_by y modified_at) antes de
# poder testear esa parte de IBP-008 CA3. Historia: IBP-008 "modificar pedido".
RSpec.describe "Pedido de punta a punta: publicar, pedir, editar y consultar" do
  fixtures :users, :providers, :consumers, :companies

  let(:p1) { providers(:tuviandita) }
  let(:p1_user) { users(:provider_user) }
  let(:p2_user) { users(:other_provider_user) }
  let(:e1) { consumers(:one) }
  let(:e1_user) { users(:one) }
  let(:e2) { consumers(:other) }
  let(:e2_user) { users(:other_consumer_user) }

  let(:monday) { Date.current.next_week(:monday) }
  let(:tuesday) { monday + 1.day }

  let!(:p1_milanesa) { p1.menus.create!(name: "Milanesa al pan", description: "Con papas", price: 300) }
  let!(:p1_wok) { p1.menus.create!(name: "Wok de vegetales", description: "Salteado", price: 290) }

  around do |example|
    travel_to(Time.zone.local(monday.year, monday.month, monday.day, 10, 0)) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    Provider.update_all(order_deadline: nil)
  end

  def open_publication_day(date)
    visit schedules_path(week_start: date.beginning_of_week(:monday).to_s)
    without_animations
    find("button", text: /\b#{date.day}\b/).click
  end

  def open_menu(as:, day:)
    sign_in as, role: :consumer
    visit dashboard_path
    without_animations
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{day.day}\b/).click }
  end

  def add_to_cart(dish, notes: nil, options: {})
    click_button "Agregar #{dish.name}"
    options.each { |group, option| pick_option(group, option) }
    fill_in "notes", with: notes if notes
    click_button "Agregar"
  end

  # Cada grupo es una <section> "Elegí tu <nombre>": buscar por el título evita
  # elegir la opción de otro grupo.
  def pick_option(group, option)
    find("section", text: "Elegí tu #{group}").find("label", text: option).click
  end

  def open_cart
    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
  end

  def use_new_address(name:, street:)
    click_button "Agregar"
    within("[role=dialog]", text: "Agregar una dirección") do
      fill_in "Nombre", with: name
      fill_in "Dirección", with: street
      click_button "Agregar"
    end
  end

  def publish(dish, date, amount: 5)
    dish.schedules.create!(date:, amount:)
  end

  def place_order(consumer, schedule, quantity: 1, notes: nil)
    Order.reserve(
      consumer:, schedule:, quantity:, notes:, delivery_method: :office,
      address: consumer.company.address, benefits: [], selected_options: selection_for(schedule.menu)
    ).tap { expect(it).to be_persisted }
  end

  def edit_order(order)
    visit order_path(order, edit: 1)
  end

  # Las dos vistas del pedido muestran solo lo elegido, no todo lo que ofrece el plato.
  def expect_chosen_garnish(chosen, instead_of:)
    expect(page).to have_content("Guarnición")
    expect(page).to have_content(chosen)
    expect(page).to have_no_content(instead_of)
  end

  # La confirmación redondea a pesos; las demás vistas usan el formato de moneda.
  def confirmation_money(amount) = "$#{amount.round}"
  def uyu(amount) = /#{amount.to_i},00/

  describe "Pasos: P1 publica y edita, E1 pide y edita, P1 consulta" do
    it "deja el mismo pedido, importe, datos y estado en la confirmación, el historial y el proveedor" do
      # P1 tiene publicado un menú para el martes.
      milanesa_tuesday = publish(p1_milanesa, tuesday, amount: 8)
      publish(p1_wok, tuesday, amount: 3)
      p1_milanesa.option_groups.create!(name: "Guarnición", options: [ "Papas", "Puré" ])

      # E1 elige fecha, plato, opción, nota, entrega y dirección, y confirma.
      open_menu(as: e1_user, day: tuesday)
      expect(page).to have_button("Agregar #{p1_wok.name}")
      click_button "Agregar #{p1_milanesa.name}"
      within("section", text: "Elegí tu Guarnición") do
        expect(page).to have_css("[role=radio]", count: 2)
      end
      expect(page).to have_button("Agregar", exact: true, disabled: true)
      click_button "Volver"
      add_to_cart(p1_milanesa, notes: "Sin sal", options: { "Guarnición" => "Puré" })
      open_cart
      expect(page).to have_content("Guarnición: Puré")
      use_new_address(name: "Estudio", street: "Colonia 1370")
      click_button "Confirmar pedido"
      expect(page).to have_content("¡Pedido recibido!")

      order = e1.orders.sole
      expect(order).to have_attributes(
        schedule: milanesa_tuesday, menu_name: "Milanesa al pan", amount: 1, notes: "Sin sal",
        delivery_method: "home", address: "Colonia 1370", status: "pending",
        selected_options: [ { "group_id" => p1_milanesa.option_groups.sole.id, "name" => "Guarnición", "values" => [ "Puré" ] } ]
      )
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content(confirmation_money(order.discounted_price))

      # E1 abre Mis pedidos y edita el pedido: cantidad, opción y nota.
      visit orders_path
      within(find("[data-slot=card]", text: "Milanesa al pan")) { click_link "Editar" }
      within("[role=dialog]") do
        click_button "Agregar uno"
        pick_option("Guarnición", "Papas")
        fill_in "notes", with: "Sin sal, con limón"
        click_button "Guardar cambios"
      end
      expect(page).to have_content("Pedido actualizado")

      edited = Order.find(order.id)
      expect(e1.orders.count).to eq(1)
      expect(edited).to have_attributes(
        amount: 2, notes: "Sin sal, con limón", price: order.price * 2,
        modified_by: e1_user, status: "pending", address: "Colonia 1370"
      )
      expect(edited.selected_options.sole["values"]).to eq([ "Papas" ])
      expect(edited.modified_at).to be_present

      visit order_path(edited)
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content("Sin sal, con limón")
      expect_chosen_garnish("Papas", instead_of: "Puré")
      expect(page).to have_content("Colonia 1370")
      expect(page).to have_content("Pendiente")
      expect(page).to have_content(uyu(edited.price))
      sign_out

      # P1 consulta el mismo pedido y ve los mismos datos.
      sign_in p1_user, role: :provider
      visit provider_order_path(edited)
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content("Sin sal, con limón")
      expect_chosen_garnish("Papas", instead_of: "Puré")
      expect(page).to have_content("Colonia 1370")
      expect(page).to have_content("Por revisar")
      expect(page).to have_content(confirmation_money(edited.price))
      expect(page).to have_content(confirmation_money(edited.discounted_price))
      sign_out

      # Persistencia: E1 vuelve a entrar y ve el pedido igual.
      sign_in e1_user, role: :consumer
      visit order_path(edited)
      expect(page).to have_content("Sin sal, con limón")
      expect_chosen_garnish("Papas", instead_of: "Puré")
      expect(page).to have_content(uyu(edited.price))
    end
  end

  describe "Repetir con plato agotado (IBP-053)" do
    let!(:wok_tuesday) { publish(p1_wok, tuesday, amount: 5) }
    let!(:e2_order) { place_order(e2, wok_tuesday) }

    def toggle_wok_stock
      sign_in p1_user, role: :provider
      open_publication_day(tuesday)
      within(find("[data-slot=card]", text: p1_wok.name)) { find("[role=switch]").click }
    end

    it "deja el plato visible como agotado, sin poder pedirlo, y registra quién y cuándo" do
      toggle_wok_stock
      expect(page).to have_css("[data-slot=card]", text: p1_wok.name) do |card|
        card.has_css?("[role=switch][aria-checked=false]")
      end
      expect(wok_tuesday.reload).to have_attributes(
        available: false, availability_changed_by: p1_user, availability_changed_at: Time.current
      )
      sign_out

      open_menu(as: e1_user, day: tuesday)
      expect(page).to have_content("Agotado")
      expect(page).to have_button("Agregar #{p1_wok.name}", disabled: true)
      expect(e1.orders).to be_empty
    end

    it "vuelve a admitir pedidos cuando el proveedor lo marca disponible otra vez" do
      wok_tuesday.set_availability(available: false, by: p1_user)
      toggle_wok_stock
      expect(page).to have_css("[role=switch][aria-checked=true]")
      sign_out

      open_menu(as: e1_user, day: tuesday)
      expect(page).to have_button("Agregar #{p1_wok.name}", disabled: false)
    end

    it "no cambia los pedidos existentes: siguen pendientes y el proveedor los gestiona" do
      toggle_wok_stock
      expect(page).to have_css("[role=switch][aria-checked=false]")

      expect(e2_order.reload).to be_pending
      visit provider_order_path(e2_order)
      expect(page).to have_content("Por revisar")
      expect(page).to have_button("Confirmar")
      expect(page).to have_button("Rechazar")
    end

    # IBP-008 CA2: al editar se vuelve a validar la disponibilidad.
    it "no deja que el empleado aumente la cantidad de un pedido sobre un plato agotado" do
      wok_tuesday.set_availability(available: false, by: p1_user)
      sign_in e2_user, role: :consumer

      edit_order(e2_order)
      within("[role=dialog]") do
        click_button "Agregar uno"
        click_button "Guardar cambios"
      end

      expect(page).to have_content("Este plato ya no está disponible para la fecha seleccionada.")
      expect(e2_order.reload.amount).to eq(1)
    end
  end

  describe "Repetir sin cupo (IBP-051 CA4, IBP-008 CA2)" do
    it "marca agotado el plato cuyo cupo ya se pidió entero" do
      wok_tuesday = publish(p1_wok, tuesday, amount: 1)
      place_order(e2, wok_tuesday)

      open_menu(as: e1_user, day: tuesday)

      expect(page).to have_content("Agotado")
      expect(page).to have_button("Agregar #{p1_wok.name}", disabled: true)
    end

    it "rechaza confirmar si otro se llevó el último lugar mientras estaba en el carrito" do
      wok_tuesday = publish(p1_wok, tuesday, amount: 1)
      open_menu(as: e1_user, day: tuesday)
      add_to_cart(p1_wok)
      open_cart

      place_order(e2, wok_tuesday)
      click_button "Confirmar pedido"

      expect(page).to have_content("Ya no hay suficiente stock para la cantidad solicitada.")
      expect(e1.orders).to be_empty
      expect(wok_tuesday.orders.count).to eq(1)
    end

    it "no deja pasar la cantidad del pedido más allá del cupo que queda" do
      wok_tuesday = publish(p1_wok, tuesday, amount: 2)
      e1_order = place_order(e1, wok_tuesday)
      place_order(e2, wok_tuesday)
      sign_in e1_user, role: :consumer

      edit_order(e1_order)

      within("[role=dialog]") { expect(page).to have_button("Agregar uno", disabled: true) }
    end

    it "refleja para el empleado el stock que el proveedor sube en un menú publicado" do
      wok_tuesday = publish(p1_wok, tuesday, amount: 1)
      place_order(e2, wok_tuesday)
      wok_tuesday.update!(amount: 4)

      open_menu(as: e1_user, day: tuesday)

      expect(page).to have_button("Agregar #{p1_wok.name}", disabled: false)
      expect(wok_tuesday.reload.id).to eq(wok_tuesday.id)
    end
  end

  describe "Repetir con hora límite vencida (IBP-066, IBP-008 CA4)" do
    let!(:milanesa_monday) { publish(p1_milanesa, monday) }

    it "no deja pedir para hoy pasada la hora límite e informa el motivo" do
      p1.update!(order_deadline: "09:00")

      open_menu(as: e1_user, day: monday)

      expect(page).to have_content("Este proveedor ya cerró la recepción de pedidos para hoy.")
      expect(page).to have_button("Agregar #{p1_milanesa.name}", disabled: true)
      expect(e1.orders).to be_empty
    end

    it "deja pedir para hoy mientras no llegó la hora límite" do
      p1.update!(order_deadline: "10:15")

      open_menu(as: e1_user, day: monday)
      add_to_cart(p1_milanesa)
      open_cart
      click_button "Confirmar pedido"

      expect(page).to have_content("¡Pedido recibido!")
      expect(e1.orders.sole.schedule).to eq(milanesa_monday)
    end

    it "conserva el estado de los pedidos hechos antes del límite" do
      order = place_order(e1, milanesa_monday)
      p1.update!(order_deadline: "09:00")
      sign_in e1_user, role: :consumer

      visit order_path(order)

      expect(page).to have_content("Pendiente")
      expect(order.reload).to be_pending
    end
  end

  describe "editar o agotar un plato no altera pedidos anteriores (IBP-050, IBP-065 CA7)" do
    let!(:milanesa_tuesday) { publish(p1_milanesa, tuesday) }
    let!(:e1_order) do
      p1_milanesa.option_groups.create!(name: "Guarnición", options: [ "Papas", "Puré" ])
      place_order(e1, milanesa_tuesday).tap { it.update!(status: :confirmed) }
    end

    it "informa la programación afectada, pide qué hacer con los confirmados y los mantiene" do
      sign_in p1_user, role: :provider
      visit edit_provider_menu_path(p1_milanesa)
      fill_in "name", with: "Milanesa napolitana", fill_options: { clear: :backspace }
      fill_in "price", with: "380", fill_options: { clear: :backspace }
      click_button "Modificar"

      expect(page).to have_content("¿Aplicar cambios desde esta fecha?")
      find("label", text: "Mantener los pedidos confirmados").click
      click_button "Aplicar cambios"
      expect(page).to have_content("¡Plato modificado!")

      expect(milanesa_tuesday.reload.menu.name).to eq("Milanesa napolitana")
      expect(e1_order.reload).to have_attributes(status: "confirmed", menu_name: "Milanesa al pan", price: 300)

      visit provider_order_path(e1_order)
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content(confirmation_money(300))
      sign_out

      sign_in e1_user, role: :consumer
      visit order_path(e1_order)
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content("Confirmado")
      expect(page).to have_content(uyu(300))
    end

    it "conserva en el pedido las opciones que tenía el plato cuando se pidió" do
      sign_in p1_user, role: :provider
      visit edit_provider_menu_path(p1_milanesa)
      click_button "Editar Guarnición"
      within("[role=dialog]") do
        fill_in "group-options", with: "Ensalada, Boniato", fill_options: { clear: :backspace }
        click_button "Modificar"
      end
      click_button "Modificar"
      click_button "Aplicar cambios"
      expect(page).to have_content("¡Plato modificado!")
      expect(p1_milanesa.reload.option_groups.sole.options).to eq([ "Ensalada", "Boniato" ])

      visit provider_order_path(e1_order)
      expect_chosen_garnish("Papas", instead_of: "Boniato")
      sign_out

      sign_in e1_user, role: :consumer
      visit order_path(e1_order)
      expect_chosen_garnish("Papas", instead_of: "Boniato")
      expect(e1_order.reload.selected_options.sole["values"]).to eq([ "Papas" ])
    end

    it "no altera los pedidos al agotar el plato" do
      milanesa_tuesday.set_availability(available: false, by: p1_user)

      expect(e1_order.reload).to have_attributes(status: "confirmed", amount: 1, price: 300)
    end
  end

  describe "IBP-050: editar la información básica de un plato sin programación" do
    before do
      sign_in p1_user, role: :provider
      visit edit_provider_menu_path(p1_wok)
      without_animations
    end

    def save_with_simple_confirmation
      click_button "Modificar"
      expect(page).to have_content("¿Modificar el plato guardado?")
      click_button "Aplicar cambios"
    end

    it "guarda nombre, descripción, precio y opciones con una confirmación simple" do
      fill_in "name", with: "Wok de pollo", fill_options: { clear: :backspace }
      fill_in "description", with: "Con fideos de arroz", fill_options: { clear: :backspace }
      fill_in "price", with: "320", fill_options: { clear: :backspace }
      click_button "Agregar", exact: true
      within("[role=dialog]") do
        fill_in "group-name", with: "Salsa"
        fill_in "group-options", with: "Soja, Agridulce"
        click_button "Agregar"
      end
      save_with_simple_confirmation

      expect(page).to have_content("¡Plato modificado!")
      expect(p1_wok.reload).to have_attributes(name: "Wok de pollo", description: "Con fideos de arroz", price: 320)
      expect(p1_wok.option_groups.pluck(:name, :options)).to eq([ [ "Salsa", [ "Soja", "Agridulce" ] ] ])
      expect(p1_wok.modified_by).to eq(p1_user)
    end

    it "borra un grupo de opciones" do
      p1_wok.option_groups.create!(name: "Salsa", options: [ "Soja" ])
      visit edit_provider_menu_path(p1_wok)
      without_animations

      click_button "Borrar Salsa"
      save_with_simple_confirmation

      expect(page).to have_content("¡Plato modificado!")
      expect(p1_wok.reload.option_groups).to be_empty
    end

    {
      "nombre vacío" => [ "name", "" ],
      "nombre solo con espacios" => [ "name", "   " ],
      "descripción vacía" => [ "description", "" ],
      "descripción solo con espacios" => [ "description", "   " ],
      "precio vacío" => [ "price", "" ]
    }.each do |label, (field, value)|
      it "rechaza #{label} y no guarda nada" do
        fill_in field, with: value, fill_options: { clear: :backspace }
        click_button "Modificar"
        click_button "Aplicar cambios" if page.has_button?("Aplicar cambios", wait: 1)

        expect(page).to have_css("[data-invalid=true]")
        expect(page).to have_no_content("¡Plato modificado!")
        expect(p1_wok.reload).to have_attributes(name: "Wok de vegetales", description: "Salteado", price: 290)
      end
    end

    { "precio cero" => "0", "precio negativo" => "-5" }.each do |label, value|
      it "rechaza #{label} y no guarda nada" do
        fill_in "price", with: value, fill_options: { clear: :backspace }
        click_button "Modificar"

        expect(page).to have_no_content("¿Modificar el plato guardado?")
        expect(p1_wok.reload.price).to eq(290)
      end
    end

    it "acepta el precio mínimo de un centésimo" do
      fill_in "price", with: "0.01", fill_options: { clear: :backspace }
      save_with_simple_confirmation

      expect(page).to have_content("¡Plato modificado!")
      expect(p1_wok.reload.price).to eq(0.01)
    end
  end

  describe "IBP-065 CA3: el diálogo de opciones no deja guardar datos inválidos" do
    before do
      sign_in p1_user, role: :provider
      visit edit_provider_menu_path(p1_wok)
      click_button "Agregar", exact: true
    end

    {
      "sin nombre" => [ "", "Soja, Agridulce" ],
      "con nombre solo de espacios" => [ "   ", "Soja" ],
      "sin alternativas" => [ "Salsa", "" ],
      "con alternativas solo de comas y espacios" => [ "Salsa", " , , " ],
      "con alternativas duplicadas" => [ "Salsa", "Soja, soja" ]
    }.each do |label, (name, options)|
      it "no deja agregar un grupo #{label}" do
        within("[role=dialog]") do
          fill_in "group-name", with: name
          fill_in "group-options", with: options
          expect(page).to have_button("Agregar", disabled: true)
        end
      end
    end
  end

  describe "IBP-051 CA4: los empleados ven los cambios del menú publicado" do
    let!(:wok_tuesday) { publish(p1_wok, tuesday) }

    it "muestra el plato que el proveedor agrega a un día ya publicado" do
      sign_in p1_user, role: :provider
      visit new_provider_menu_path(date: tuesday.iso8601)
      without_animations
      click_on "Platos guardados"
      click_button "Agregar #{p1_milanesa.name} a la selección"
      click_button "Agregar", exact: true
      expect(page).to have_button("Agregar #{p1_milanesa.name} a la selección", disabled: true)
      sign_out

      open_menu(as: e1_user, day: tuesday)

      expect(page).to have_content(p1_milanesa.name)
      expect(page).to have_content(p1_wok.name)
    end

    it "deja de mostrar el plato que el proveedor quita de un día" do
      publish(p1_milanesa, tuesday)
      open_menu(as: e1_user, day: tuesday)
      expect(page).to have_content(p1_milanesa.name)
      sign_out

      sign_in p1_user, role: :provider
      open_publication_day(tuesday)
      within(find("[data-slot=card]", text: p1_milanesa.name)) { click_button "Quitar" }
      within("[role=dialog]") { click_button "Quitar" }
      expect(page).to have_content("Plato quitado del menú.")
      sign_out

      open_menu(as: e1_user, day: tuesday)

      expect(page).to have_no_content(p1_milanesa.name)
      expect(page).to have_content(p1_wok.name)
    end
  end

  describe "IBP-051 CA5: editar un menú publicado no cambia los pedidos ya creados" do
    let!(:milanesa_tuesday) { publish(p1_milanesa, tuesday, amount: 5) }
    let!(:wok_tuesday) { publish(p1_wok, tuesday, amount: 5) }
    let!(:e1_order) { place_order(e1, milanesa_tuesday, quantity: 2) }

    it "mantiene el pedido al bajar el stock del plato" do
      milanesa_tuesday.update!(amount: 3)

      expect(e1_order.reload).to have_attributes(status: "pending", amount: 2, schedule_id: milanesa_tuesday.id)
    end
  end

  describe "IBP-008: qué se puede modificar y cuándo" do
    let!(:milanesa_tuesday) { publish(p1_milanesa, tuesday) }

    it "no deja editar un pedido que el proveedor ya confirmó" do
      order = place_order(e1, milanesa_tuesday).tap { it.update!(status: :confirmed) }
      sign_in e1_user, role: :consumer

      visit order_path(order)

      expect(page).to have_button("Editar", disabled: true)
    end

    it "deja cambiar la dirección a otra guardada y la ve el proveedor" do
      e1.saved_addresses.create!(name: "Estudio", street: "Colonia 1370")
      order = place_order(e1, milanesa_tuesday)
      sign_in e1_user, role: :consumer

      edit_order(order)
      within("[role=dialog]") do
        find("label", text: "Colonia 1370").click
        click_button "Guardar cambios"
      end
      expect(page).to have_content("Pedido actualizado")
      expect(order.reload).to have_attributes(delivery_method: "home", address: "Colonia 1370")
      sign_out

      sign_in p1_user, role: :provider
      visit provider_order_path(order)
      expect(page).to have_content("Colonia 1370")
    end
  end

  describe "IBP-022 CA3: la nota tiene un máximo de 140 caracteres" do
    let!(:milanesa_tuesday) { publish(p1_milanesa, tuesday) }

    it "no deja escribir más de 140 caracteres al pedir" do
      open_menu(as: e1_user, day: tuesday)
      click_button "Agregar #{p1_milanesa.name}"

      fill_in "notes", with: "a" * 141

      expect(find_field("notes").value.length).to eq(140)
    end
  end

  describe "IBP-068: P1 cambia las modalidades y E1 solo elige las habilitadas" do
    # El switch cambia al instante y queda deshabilitado mientras dura el PATCH:
    # esperar el estado nuevo prueba que React ya hidrató, y esperar que se
    # habilite otra vez, que el servidor respondió.
    def turn_off_home_delivery
      visit settings_profile_path
      without_animations
      switch = find("#home_delivery:not([disabled])")
      switch.click
      switch.click unless has_css?("#home_delivery[aria-checked=false]", wait: 1)
      expect(page).to have_css("#home_delivery[aria-checked=false]")
      expect(page).to have_css("#home_delivery:not([disabled])")
    end

    it "deja pedir solo en la oficina y no toca el pedido a domicilio ya creado" do
      milanesa_tuesday = publish(p1_milanesa, tuesday)
      order = place_order(e1, milanesa_tuesday)
      order.update!(delivery_method: :home, address: "Colonia 1370")

      # CA1 y CA2: P1 deja de entregar a domicilio desde su configuración.
      sign_in p1_user, role: :provider
      turn_off_home_delivery
      expect(p1.reload.home_delivery).to be(false)
      expect(providers(:endulzate).reload.home_delivery).to be(true)
      # CA4: la oficina sigue habilitada y el menú publicado sigue en pie.
      expect(milanesa_tuesday.reload).to be_persisted
      sign_out

      # CA3: E1 ya no puede elegir su casa para ese proveedor.
      open_menu(as: e1_user, day: tuesday)
      add_to_cart(p1_milanesa)
      open_cart
      expect(find("label", text: "Colonia 1370").find("[role=radio]")).to be_disabled
      expect(page).to have_css("label", text: e1.company.address, class: /border-primary/)
      click_button "Confirmar pedido"
      expect(page).to have_content("¡Pedido recibido!")
      expect(e1.orders.order(:id).last).to have_attributes(
        delivery_method: "office", address: e1.company.address
      )

      # CA5: el pedido anterior sigue a domicilio para los dos roles.
      visit order_path(order)
      expect(page).to have_content("Colonia 1370")
      sign_out

      sign_in p1_user, role: :provider
      visit provider_order_path(order)
      expect(page).to have_content("Colonia 1370")
      expect(order.reload).to have_attributes(delivery_method: "home", address: "Colonia 1370")
    end
  end

  describe "permisos y privacidad entre pares" do
    let!(:milanesa_tuesday) { publish(p1_milanesa, tuesday) }
    let!(:e1_order) { place_order(e1, milanesa_tuesday, notes: "Sin sal") }

    it "P2 no ve el pedido de P1 entrando por URL" do
      sign_in p2_user, role: :provider
      visit provider_order_path(e1_order)

      expect(page).to have_no_content("Sin sal")
      expect(page).to have_no_content(p1_milanesa.name)
    end

    it "P2 no abre la edición de un plato de P1 entrando por URL" do
      sign_in p2_user, role: :provider
      visit edit_provider_menu_path(p1_milanesa)

      expect(page).to have_no_field("name", with: p1_milanesa.name)
    end

    it "E2 no ve el pedido de E1 entrando por URL" do
      sign_in e2_user, role: :consumer
      visit order_path(e1_order)

      expect(page).to have_no_content("Sin sal")
    end

    it "un empleado no llega a la edición de platos" do
      sign_in e1_user, role: :consumer
      visit edit_provider_menu_path(p1_milanesa)

      expect(page).to have_no_current_path(edit_provider_menu_path(p1_milanesa))
    end

    it "un visitante sin sesión no ve el pedido" do
      visit order_path(e1_order)

      expect(page).to have_current_path(sign_in_path)
    end
  end
end
