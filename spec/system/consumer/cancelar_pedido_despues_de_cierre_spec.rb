# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cancelar pedidos después de la hora de cierre e información de pedidos", type: :system do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus, :schedules, :orders,
           :accounts, :order_accounts, :benefits, :benefit_configurations, :benefit_rules, :order_benefits

  let(:consumer_user) { users(:one) }
  let(:pending_today_order) { orders(:upcoming_pending_today) }
  let(:cancelled_order) { orders(:history_cancelled_future) }
  let(:rejected_order) { orders(:history_rejected_future) }
  let(:confirmed_past_order) { orders(:history_confirmed_past) }
  let(:provider) { pending_today_order.schedule.menu.provider }

  describe "bloqueo de cancelación luego de la hora de cierre del proveedor" do
    it "deshabilita el botón de cancelar y muestra el mensaje explicativo en el listado y detalle" do
      provider.update!(order_deadline: "12:00")

      travel_to(Time.zone.today.in_time_zone.change(hour: 15, min: 0)) do
        sign_in consumer_user, role: :consumer
        visit_hydrated orders_path

        card = find("a[href='#{order_path(pending_today_order)}']").ancestor("[data-slot='card']")
        within card do
          expect(page).to have_button("Cancelar", disabled: true)
          expect(page).to have_content("El proveedor ya cerró la recepción de pedidos de hoy, así que no se puede cancelar.")
        end

        visit_hydrated order_path(pending_today_order)
        expect(page).to have_button("Cancelar", disabled: true)
        expect(page).to have_content("El proveedor ya cerró la recepción de pedidos de hoy, así que no se puede cancelar.")
      end
    end
  end

  describe "información de dirección y estado en pedidos del historial" do
    let(:confirmed_upcoming_order) { orders(:upcoming_confirmed_future) }

    it "muestra 'Lo pediste para:' en cancelados/rechazados, 'Lo recibiste en:' y 'Entregado' en confirmados pasados" do
      sign_in consumer_user, role: :consumer
      visit_hydrated orders_path

      # En próximos, un pedido confirmado dice "Confirmado"
      upcoming_card = find("a[href='#{order_path(confirmed_upcoming_order)}']").ancestor("[data-slot='card']")
      within upcoming_card do
        expect(page).to have_content("Confirmado")
        expect(page).to have_no_content("Entregado")
      end

      find("button", text: "Historial").click

      cancelled_card = find("a[href='#{order_path(cancelled_order)}']").ancestor("[data-slot='card']")
      within cancelled_card do
        expect(page).to have_content("Lo pediste para: #{cancelled_order.address}")
        expect(page).to have_no_content("Lo recibiste en:")
        expect(page).to have_content("Cancelado")
      end

      rejected_card = find("a[href='#{order_path(rejected_order)}']").ancestor("[data-slot='card']")
      within rejected_card do
        expect(page).to have_content("Lo pediste para: #{rejected_order.address}")
        expect(page).to have_no_content("Lo recibiste en:")
        expect(page).to have_content("Rechazado")
      end

      confirmed_card = find("a[href='#{order_path(confirmed_past_order)}']").ancestor("[data-slot='card']")
      within confirmed_card do
        expect(page).to have_content("Lo recibiste en: #{confirmed_past_order.address}")
        expect(page).to have_content("Entregado")
        expect(page).to have_no_content("Confirmado")
      end
    end
  end

  describe "despliegue de direcciones y stock en edición de pedido" do
    let(:modifiable_order) { orders(:upcoming_pending_future) }

    it "muestra la oficina y la dirección seleccionada sin texto de stock restante" do
      sign_in consumer_user, role: :consumer
      visit_hydrated order_path(modifiable_order, edit: 1)

      expect(page).to have_button("Modificar")
      expect(page).to have_content("18 de Julio 1006")
      expect(page).to have_content("Julio Herrera y Reissig 565")
      expect(page).to have_no_content("disponibles para esta fecha")
    end
  end
end
