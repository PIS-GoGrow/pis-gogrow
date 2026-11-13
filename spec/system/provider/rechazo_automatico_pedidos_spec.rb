# frozen_string_literal: true

# Solicitud de cambio SC-007 sobre IBP-057: "Como cliente (GoGrow) quiero que los
# proveedores tengan un margen de 30 minutos pasada su hora de cierre para
# confirmar o cancelar pedidos y que, si no lo hacen, los pedidos pendientes se
# cancelen automáticamente, para que el empleado tenga la certeza de que su pedido
# no le va a llegar y pueda pedirle a otro proveedor antes de que cierre."
# Lo que ve el empleado y RR. HH. se cubre en
# spec/system/consumer/pedido_rechazado_sin_respuesta_spec.rb.
#
# TODO(integración): falta mostrarle al proveedor hasta qué hora puede responder
# (cierre + 30 min) antes de poder testear que ve la hora límite de respuesta en
# sus pedidos. Historia: SC-007 "margen de 30 minutos y rechazo automático".
#
# Rechazar un pedido ya confirmado después del margen sigue permitido; la
# solicitud es ambigua sobre eso, así que no se fija en ningún test.

require "rails_helper"

RSpec.describe "Rechazo automático de pedidos sin respuesta del proveedor", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }
  # Un lunes futuro: el servidor lo toma como "hoy" y el navegador, que no viaja
  # en el tiempo, no lo marca como fecha pasada. Una semana más allá del próximo
  # para no caer nunca en hoy + 3, la fecha de schedules(:future) de la milanesa.
  let(:monday) { Date.current.next_week(:monday) + 1.week }
  let(:message) { I18n.t("validations.order_response_window_closed") }

  around do |example|
    travel_to(at(11, 0)) { example.run }
  end

  before do
    provider.update!(order_deadline: "12:00")
    page.current_window.resize_to(1400, 1400)
  end

  def at(hour, min) = Time.zone.local(monday.year, monday.month, monday.day, hour, min)

  def order_for(date, menu: milanesa, status: :pending)
    Order.create!(
      consumer: consumers(:one), schedule: menu.schedules.find_or_create_by!(date:), amount: 1,
      price: menu.price, discounted_price: menu.price, delivery_method: :office, status:
    )
  end

  def open_order_as_provider(order)
    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_order_path(order)
    without_animations
  end

  def reject_from_dialog
    click_button "Rechazar"
    expect(page).to have_content("¿Rechazar pedido?")
    find("#reason-out_of_stock").click
    click_button "Rechazar pedido"
  end

  # Criterio 1: dentro de la media hora después del cierre todavía puede responder.
  describe "dentro del margen" do
    it "deja confirmar un pendiente de hoy a los 10 minutos del cierre" do
      order = order_for(monday)
      travel_to at(12, 10)

      sign_in users(:provider_user), role: :provider
      visit_hydrated provider_orders_path
      within(provider_order_card(order)) do
        click_button "Confirmar"
        expect(page).to have_content("Confirmado")
      end

      expect(order.reload).to be_confirmed
    end

    it "deja rechazar un pendiente de hoy un minuto antes de que termine el margen" do
      order = order_for(monday)
      travel_to at(12, 29)

      open_order_as_provider(order)
      reject_from_dialog

      expect(page).to have_content("Pedido rechazado")
      expect(order.reload).to have_attributes(status: "rejected", rejection_reason: "out_of_stock")
    end
  end

  # Criterio 2: pasada la media hora ya no puede confirmar ni rechazar, aunque el
  # job todavía no haya corrido y la pantalla le siga mostrando los botones.
  describe "pasado el margen, antes de que corra el job" do
    it "no deja confirmar y explica por qué" do
      order = order_for(monday)
      open_order_as_provider(order)
      travel_to at(12, 30)

      click_button "Confirmar"

      expect(page).to have_content(message)
      expect(order.reload).to be_pending
    end

    it "no deja rechazar con otro motivo y explica por qué" do
      order = order_for(monday)
      open_order_as_provider(order)
      travel_to at(12, 31)

      reject_from_dialog

      expect(page).to have_content(message)
      expect(order.reload).to have_attributes(status: "pending", rejection_reason: nil)
    end
  end

  # Criterios 3, 6 y 7: el job rechaza solo los pendientes de hoy de un proveedor
  # con hora de cierre, y el proveedor lo ve con el motivo en la lista y el detalle.
  describe "cuando corre el job" do
    it "rechaza el pendiente de hoy con el motivo sin respuesta y el proveedor lo ve" do
      order = order_for(monday)
      travel_to at(12, 30)

      UnansweredOrdersRejectionJob.perform_now

      expect(order.reload).to have_attributes(status: "rejected", rejection_reason: "no_response")

      sign_in users(:provider_user), role: :provider
      visit_hydrated provider_orders_path
      within(provider_order_card(order)) do
        expect(page).to have_content("Rechazado")
        expect(page).to have_no_button("Confirmar")
        expect(page).to have_no_button("Rechazar")
      end

      visit_hydrated provider_order_path(order)
      expect(page).to have_content("Sin respuesta del proveedor")
      expect(page).to have_no_button("Confirmar")
    end

    # El riesgo principal de la solicitud: no pisar lo que el proveedor ya respondió.
    it "no toca un pedido que el proveedor confirmó dentro del margen" do
      order = order_for(monday)
      travel_to at(12, 20)
      sign_in users(:provider_user), role: :provider
      visit_hydrated provider_orders_path
      within(provider_order_card(order)) do
        click_button "Confirmar"
        expect(page).to have_content("Confirmado")
      end

      travel_to at(12, 31)
      UnansweredOrdersRejectionJob.perform_now

      expect(order.reload).to be_confirmed
      visit_hydrated provider_order_path(order)
      expect(page).to have_content("Confirmado")
      expect(page).to have_no_content("Sin respuesta del proveedor")
    end

    it "no toca los pendientes de mañana ni los de un proveedor sin hora de cierre" do
      tomorrow = order_for(monday + 1)
      endulzate = providers(:endulzate)
      endulzate.update!(order_deadline: nil)
      no_deadline = order_for(monday, menu: endulzate.menus.create!(name: "Tarta", description: "De verdura", price: 280))
      travel_to at(18, 0)

      UnansweredOrdersRejectionJob.perform_now

      expect(tomorrow.reload).to be_pending
      expect(no_deadline.reload).to be_pending

      sign_in users(:provider_user), role: :provider
      visit_hydrated provider_orders_path
      within(provider_order_card(tomorrow)) do
        expect(page).to have_button("Confirmar")
      end
    end
  end

  # Privacidad entre pares: el pedido rechazado de un proveedor no lo ve otro.
  it "no le muestra a otro proveedor el pedido rechazado automáticamente" do
    order = order_for(monday)
    travel_to at(12, 30)
    UnansweredOrdersRejectionJob.perform_now

    sign_in users(:other_provider_user), role: :provider
    visit provider_order_path(order)

    expect(page).to have_no_content("Sin respuesta del proveedor")
    expect(page).to have_no_content("PED-#{order.id}")
  end
end
