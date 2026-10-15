# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Acceso a la pantalla de confirmación de pedido", type: :system do
  fixtures :users, :consumers, :orders, :schedules, :menus, :companies

  let(:consumer_user) { users(:one) }
  let(:own_order) { orders(:upcoming_pending_future) }
  let(:other_order) { orders(:other_consumer_upcoming) }

  before do
    page.current_window.resize_to(1400, 1400)
    sign_in consumer_user, role: :consumer
  end

  describe "Navegación directa o manipulación de parámetros" do
    it "redirige al dashboard al acceder directamente sin parámetros" do
      visit dashboard_confirmation_path

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_no_content("¡Pedido recibido!")
    end

    it "redirige al dashboard con identificadores no válidos o de tipo inesperado" do
      visit "#{dashboard_confirmation_path}?confirmed_order_ids[]=invalido"

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_no_content("¡Pedido recibido!")
    end

    it "redirige al dashboard cuando se ingresa el ID de un pedido perteneciente a otro empleado" do
      visit dashboard_confirmation_path(confirmed_order_ids: [ other_order.id ])

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_no_content("¡Pedido recibido!")
      expect(page).to have_no_content(other_order.address)
    end
  end

  describe "Acceso legítimo con pedido válido del empleado" do
    it "muestra la pantalla de confirmación con los datos del pedido" do
      visit dashboard_confirmation_path(confirmed_order_ids: [ own_order.id ])

      expect(page).to have_current_path(dashboard_confirmation_path(confirmed_order_ids: [ own_order.id ]))
      expect(page).to have_content("¡Pedido recibido!")
      expect(page).to have_content("Te notificaremos cuando el proveedor confirme tu pedido.")
      expect(page).to have_content(own_order.address)
      expect(page).to have_link("Ver mis pedidos", href: orders_path)
    end
  end
end
