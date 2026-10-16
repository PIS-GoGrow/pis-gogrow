# frozen_string_literal: true

require "rails_helper"

RSpec.describe "REG-04: Regresión de cancelación de pedidos", type: :system do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus, :schedules, :orders,
           :accounts, :order_accounts, :benefits, :benefit_configurations, :benefit_rules, :order_benefits

  let(:consumer_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:benefit) { benefits(:monthly) }
  let(:sched_today) { schedules(:today) }
  let(:sched_future) { schedules(:future) }

  before do
    sched_today.update!(amount: 10, available: true)
    sched_future.update!(amount: 10, available: true)
    provider.update!(order_deadline: 2.hours.from_now.strftime("%H:%M"))
  end

  def reserve_subsidized_order(schedule:)
    Order.reserve(
      consumer:,
      schedule:,
      delivery_method: :office,
      address: "18 de Julio 1006",
      quantity: 1,
      discount_percentage: benefit.percentage,
      subsidized_quantity: 1,
      benefits: [ benefit ]
    )
  end

  describe "Paso 1: Cancelación permitida dentro del plazo límite (CAG-04, CAG-06, CAG-07)" do
    it "cancela Orden 1 en plazo, registra trazabilidad, restituye el subsidio y actualiza el panel del proveedor" do
      initial_stock = sched_today.remaining_amount
      order_1 = reserve_subsidized_order(schedule: sched_today)

      expect(order_1).to be_persisted
      expect(order_1).to be_pending
      expect(consumer.monthly_benefit_used_this_month).to eq(1)
      expect(consumer.remaining_monthly_benefit).to eq(19)
      expect(sched_today.reload.remaining_amount).to eq(initial_stock - 1)

      # 1.1: Autenticarse como E1 y verificar consumo inicial en dashboard y navegar a Mis Órdenes
      sign_in consumer_user, role: :consumer
      visit dashboard_path
      expect(page).to have_content("1 de 5")

      visit orders_path
      sleep 1.5

      # 1.2: Seleccionar Orden 1 y confirmar cancelación
      within find("a[href='#{order_path(order_1)}']").ancestor("[data-slot='card']") do
        click_button "Cancelar"
      end

      expect(page).to have_content("¿Cancelar pedido?")
      click_button "Cancelar pedido"

      # 1.3: Verificar transición inmediata a Cancelado y registro de trazabilidad (CAG-07)
      expect(page).to have_content("Pedido cancelado.")
      order_1.reload
      expect(order_1.status).to eq("cancelled")
      expect(order_1.status_before_cancellation).to eq("pending")
      expect(order_1.cancelled_by).to eq(consumer_user)
      expect(order_1.cancelled_at).to be_present

      find("button", text: "Historial").click
      expect(page).to have_content("Cancelado")

      # 1.4: Comprobar restitución automática del cupo de subsidio y stock en vista de E1
      expect(consumer.reload.monthly_benefit_used_this_month).to eq(0)
      expect(consumer.remaining_monthly_benefit).to eq(20)
      expect(sched_today.reload.remaining_amount).to eq(initial_stock)

      visit dashboard_path
      expect(page).to have_content("0 de 5")

      sign_out

      # 1.4 (CAG-04): Consistencia en el listado operativo de P1
      sign_in provider_user, role: :provider
      visit provider_orders_path
      sleep 1.5

      find("button", text: "Pendientes").click
      expect(page).to have_no_content("PED-#{order_1.id}")

      find("button", text: "Cancelados").click
      expect(page).to have_content("PED-#{order_1.id}")
      expect(page).to have_content("Cancelado")
    end
  end

  describe "Paso 2: Intento de cancelación fuera de plazo (CAG-05)" do
    it "2.1 y 2.2 deshabilita el botón de cancelar y muestra mensaje explicativo en pedidos fuera de ventana" do
      order_confirmed_today = reserve_subsidized_order(schedule: sched_today)
      order_confirmed_today.update!(status: :confirmed)
      order_past_pending = orders(:history_pending_past)

      sign_in consumer_user, role: :consumer
      visit orders_path

      within find("a[href='#{order_path(order_confirmed_today)}']").ancestor("[data-slot='card']") do
        expect(page).to have_button("Cancelar", disabled: true)
      end

      visit order_path(order_past_pending)
      expect(page).to have_button("Cancelar", disabled: true)
      expect(page).to have_content("Este pedido ya está cerrado.")
    end

    it "2.3 bloquea la cancelación forzada fuera de plazo manteniendo estado y subsidio inalterados" do
      order_confirmed_today = reserve_subsidized_order(schedule: sched_today)
      order_confirmed_today.update!(status: :confirmed)
      order_past_pending = orders(:history_pending_past)

      expect(consumer.remaining_monthly_benefit).to eq(19)

      expect(order_confirmed_today.cancel(by: consumer_user)).to be(false)
      expect(order_confirmed_today.reload.status).to eq("confirmed")
      expect(order_confirmed_today.cancelled_at).to be_nil
      expect(consumer.reload.remaining_monthly_benefit).to eq(19)

      expect(order_past_pending.cancel(by: consumer_user)).to be(false)
      expect(order_past_pending.reload.status).to eq("pending")
      expect(order_past_pending.cancelled_at).to be_nil
    end
  end

  describe "Paso 3: Repetición de solicitud sobre pedidos rechazados o procesados (CAG-06)" do
    it "3.1 impide cancelar la Orden 3 previamente rechazada por el proveedor sin alterar estado ni subsidio" do
      order_3 = reserve_subsidized_order(schedule: sched_future)
      expect(order_3.decide(:rejected, reason: :out_of_stock)).to be(true)

      # Al ser rechazada, el subsidio ya fue restituido (20 disponibles)
      expect(consumer.reload.remaining_monthly_benefit).to eq(20)

      sign_in consumer_user, role: :consumer
      visit order_path(order_3)

      expect(page).to have_content("Rechazado")
      expect(page).to have_button("Cancelar", disabled: true)
      expect(page).to have_content("Este pedido ya está cerrado.")

      # Intento forzado de cancelación sobre pedido rechazado
      expect(order_3.cancel(by: consumer_user)).to be(false)
      order_3.reload
      expect(order_3.status).to eq("rejected")
      expect(order_3.rejection_reason).to eq("out_of_stock")
      expect(order_3.cancelled_at).to be_nil
      expect(order_3.cancelled_by).to be_nil
      expect(consumer.reload.remaining_monthly_benefit).to eq(20)
    end

    it "3.2 y 3.3 rechaza peticiones duplicadas de cancelación sobre Orden 1 sin sobrescribir trazabilidad ni duplicar devolución" do
      initial_stock = sched_future.remaining_amount
      order_1 = reserve_subsidized_order(schedule: sched_future)

      expect(consumer.reload.remaining_monthly_benefit).to eq(19)
      expect(order_1.cancel(by: consumer_user)).to be(true)

      first_cancelled_at = order_1.reload.cancelled_at
      expect(consumer.reload.remaining_monthly_benefit).to eq(20)
      expect(sched_future.reload.remaining_amount).to eq(initial_stock)

      # Segunda solicitud de cancelación (duplicada)
      expect(order_1.cancel(by: consumer_user)).to be(false)
      order_1.reload
      expect(order_1.status).to eq("cancelled")
      expect(order_1.cancelled_at).to eq(first_cancelled_at)
      expect(order_1.cancelled_by).to eq(consumer_user)
      expect(consumer.reload.remaining_monthly_benefit).to eq(20)
      expect(sched_future.reload.remaining_amount).to eq(initial_stock)
    end
  end

  describe "Paso 4: Resolución de regla de negocio para pedidos del mismo día (IBP-066, IBP-067)" do
    it "4.1 aprueba la cancelación y reembolsa el subsidio si el pedido del día está antes de la hora límite de P1" do
      provider.update!(order_deadline: 2.hours.from_now.strftime("%H:%M"))
      expect(sched_today.order_deadline_passed?).to be(false)

      same_day_order = reserve_subsidized_order(schedule: sched_today)
      expect(consumer.reload.remaining_monthly_benefit).to eq(19)
      expect(same_day_order).to be_cancellable

      sign_in consumer_user, role: :consumer
      visit order_path(same_day_order)
      sleep 1.5

      click_button "Cancelar"
      expect(page).to have_content("¿Cancelar pedido?")
      click_button "Cancelar pedido"

      expect(page).to have_content("Pedido cancelado.")
      expect(same_day_order.reload.status).to eq("cancelled")
      expect(consumer.reload.remaining_monthly_benefit).to eq(20)
    end

    it "4.2 verifica el corte de horario límite de P1 para el mismo día y el bloqueo al confirmarse" do
      same_day_order = reserve_subsidized_order(schedule: sched_today)

      # Cuando expira la hora límite configurada por P1 (IBP-066 / IBP-067):
      provider.update!(order_deadline: 2.hours.ago.strftime("%H:%M"))
      expect(sched_today.reload.order_deadline_passed?).to be(true)
      expect(sched_today.available?).to be(false)

      late_order = reserve_subsidized_order(schedule: sched_today)
      expect(late_order).not_to be_persisted
      expect(late_order.errors[:schedule_id]).to include("Este proveedor ya cerró la recepción de pedidos para hoy.")

      # Al ser confirmado para el día de hoy, la cancelación queda bloqueada ('confirmed_for_today')
      same_day_order.update!(status: :confirmed)
      expect(same_day_order.reload).not_to be_cancellable
      expect(same_day_order.cancellation_block_reason).to eq("confirmed_for_today")

      sign_in consumer_user, role: :consumer
      visit order_path(same_day_order)
      expect(page).to have_content("Confirmado")
      expect(page).to have_button("Cancelar", disabled: true)

      expect(same_day_order.cancel(by: consumer_user)).to be(false)
      expect(same_day_order.reload.status).to eq("confirmed")
    end
  end
end
