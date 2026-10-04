# frozen_string_literal: true

require "rails_helper"

# Historia IBP-068: "Como PROVEEDOR, quiero indicar si realizo entregas a
# domicilio o únicamente a la oficina de GoGrow, para que los empleados solo
# puedan elegir modalidades que puedo cumplir."
#
# Esta es la mitad del empleado: el aviso y la coerción a oficina cuando el
# proveedor no entrega a domicilio. La pantalla es el carrito del /dashboard,
# una vista sin ruta propia, y la confirmación que sigue al pedido.
#
# El criterio 4 ("al menos una modalidad debe permanecer habilitada") no se
# repite acá: es una regla sobre la configuración del proveedor, cubierta en
# provider/configurar_modalidad_de_entrega_spec.rb.
#
# TODO(integración): falta bloquear la dirección de casa en el carrito antes de
# poder testear el criterio 3 al pie de la letra ("los empleados solo pueden
# seleccionar las modalidades habilitadas"). Hoy el empleado sí puede elegir la
# dirección de casa con un proveedor que no entrega a domicilio: el radio queda
# habilitado y lo que hace la app es avisarle y coercionar el pedido a oficina
# en el servidor (Consumer#delivery_for). El resultado final del pedido es el
# que el criterio pide, pero el control no se puede seleccionar. Historia,
# criterio 3.
RSpec.describe "Elegir la modalidad de entrega como empleado" do
  fixtures :users, :consumers, :companies, :providers, :menus

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:office_address) { companies(:gogrow).address }
  let(:home_address) { consumers(:one).address }

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
  end

  def publish(menu, date = monday, amount: 5)
    Schedule.create!(menu:, date:, amount:)
  end

  # El dashboard se sirve por SSR y React hidrata después. Un click que cae antes
  # de la hidratación no dispara ningún handler y la pantalla no cambia: el
  # click se reintenta hasta que aparezca el texto que prueba que la vista cambió.
  # No es un sleep — es esperar una condición observable, con reintentos.
  def click_until(selector, expected_text)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        find(selector).click
        break if page.has_text?(expected_text, wait: 0.5)
      rescue Capybara::ElementNotFound
        sleep 0.3
      end
    end
  end

  # El plato se abre por su aria-label y se agrega desde la barra de acción del
  # detalle. El click va con exact: true porque el control de cantidad tiene
  # aria-label "Agregar uno" y un click_button "Agregar" sin exacto le puede
  # pegar a ese en vez de al botón de agregar al carrito.
  def add_to_cart(menu_name)
    click_until("button[aria-label='Agregar #{menu_name}']", "Monto a pagar")
    find_button("Agregar", exact: true).click
    # "Ver carrito" recién se habilita cuando el estado de React corrió, así que
    # se espera a que esté habilitado antes de clickearlo.
    find_button("Ver carrito", exact: true, wait: Capybara.default_max_wait_time).click
    expect(page).to have_content("Dirección de entrega")
  end

  # El radio no lleva el texto de la dirección: la dirección está en un <small>
  # hermano, dentro del <label> que envuelve al radio. Por eso se busca el label
  # que nombra la dirección y se clickea el radio que tiene adentro.
  #
  # No necesita reintento por hidratación: para que el carrito exista hubo que
  # clickear "Ver carrito", que es un cambio de estado de React, así que la
  # pantalla del carrito ya está hidratada cuando se elige la dirección.
  def pick_address(address)
    find("label", text: address).find("[role=radio]").click
    expect(page).to have_css("label", text: address, class: /border-primary/)
  end

  # Un solo click: para llegar al botón de confirmar hubo que pasar por un
  # cambio de estado de React (abrir el carrito), así que la pantalla ya está
  # hidratada y el handler responde. La confirmación se espera con un matcher,
  # que reintenta solo.
  def confirm_order
    find_button("Confirmar pedido", exact: true).click
    expect(page).to have_content("¡Pedido recibido!")
  end

  # Criterio 3 — un proveedor que sí entrega a domicilio: el empleado elige casa
  # y el pedido sale con esa modalidad, sin avisos.
  it "delivers to the address the employee picked when the provider does home delivery" do
    publish(menus(:milanesa))
    sign_in users(:one), role: :consumer

    visit dashboard_path
    add_to_cart "Milanesa con papas fritas"
    pick_address home_address

    expect(page).to have_no_content(I18n.t("pages.cart.office_delivery_warning", provider: providers(:tuviandita).user.name))
    confirm_order

    order = consumers(:one).orders.sole
    expect(order).to have_attributes(delivery_method: "home", address: home_address)
    expect(page).to have_content("Domicilio")
    expect(page).to have_content(home_address)
  end

  # Criterio 3 — un proveedor que no entrega a domicilio: el carrito bloquea la
  # dirección de casa y fuerza la entrega en la oficina.
  it "disables home delivery for an office-only provider" do
    publish(menus(:office_menu))
    sign_in users(:one), role: :consumer

    visit dashboard_path
    add_to_cart "Ensalada de quinoa"

    expect(find("label", text: home_address).find("[role=radio]")).to be_disabled
    expect(page).to have_css("label", text: office_address, class: /border-primary/)
  end

  # Criterio 3 — el efecto real: el pedido se guarda con la modalidad y la
  # dirección de la oficina.
  it "saves an office delivery for an office-only provider" do
    publish(menus(:office_menu))
    sign_in users(:one), role: :consumer

    visit dashboard_path
    add_to_cart "Ensalada de quinoa"
    confirm_order

    order = consumers(:one).orders.sole
    expect(order).to have_attributes(delivery_method: "office", address: office_address)
    expect(page).to have_content("Oficina")
    expect(page).to have_content(office_address)
  end


  # Transversal — consistencia entre vistas: la modalidad que el empleado ve en la
  # confirmación es la misma que el proveedor ve en el pedido. Si divergieran, el
  # proveedor organizaría la entrega con un dato que el empleado no pidió.
  it "shows the employee and the provider the same delivery method" do
    publish(menus(:milanesa))
    sign_in users(:one), role: :consumer

    visit dashboard_path
    add_to_cart "Milanesa con papas fritas"
    pick_address home_address
    confirm_order

    order = consumers(:one).orders.sole
    expect(page).to have_content("Domicilio")

    sign_out
    sign_in providers(:tuviandita).user, role: :provider

    visit provider_order_path(order)

    expect(page).to have_content("Domicilio")
    expect(page).to have_content(home_address)
  end

  # Transversal — permisos: el empleado no puede cambiar la modalidad del
  # proveedor. El switch está en /settings/profile y el serializer lo manda en nil
  # para el rol consumidor; el request spec cubre que el PATCH se ignora, acá se
  # chequea que no se vea.
  it "does not let a consumer reach the provider's delivery setting" do
    sign_in users(:one), role: :consumer

    visit settings_profile_path

    expect(page).to have_no_selector("#home_delivery")
    expect(page).to have_no_content(I18n.t("pages.settings.profile.home_delivery.label"))
  end
end
