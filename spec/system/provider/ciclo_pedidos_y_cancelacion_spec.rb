# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SYS-04: Ciclo de decisión del proveedor y cancelación de pedidos", type: :system do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus, :schedules, :orders,
           :accounts, :order_accounts, :benefits, :benefit_configurations, :benefit_rules

  let(:consumer_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:other_provider_user) { users(:other_provider_user) }
  let(:milanesa) { menus(:milanesa) }
  let(:sched_today) { schedules(:today) }
  let(:sched_future) { schedules(:future) }

  let!(:order_a) do
    Order.create!(
      consumer:,
      schedule: sched_today,
      status: :pending,
      amount: 1,
      price: 300,
      discounted_price: 150,
      delivery_method: :office,
      address: "18 de Julio 1006"
    )
  end

  let!(:order_b) do
    Order.create!(
      consumer:,
      schedule: sched_future,
      status: :pending,
      amount: 1,
      price: 300,
      discounted_price: 150,
      delivery_method: :office,
      address: "18 de Julio 1006"
    )
  end

  describe "Paso 1: Gestión de confirmación y rechazo con motivo por el proveedor" do
    it "permite confirmar y rechazar con motivo obligatorio y refleja los estados en el empleado" do
      # 1.1 y 1.2: Proveedor confirma Orden A
      sign_in provider_user, role: :provider
      visit provider_order_path(order_a)

      sleep 1.5
      find_button("Confirmar").click
      expect(page).to have_content("Pedido confirmado.")
      expect(order_a.reload.status).to eq("confirmed")

      # 1.3: Proveedor rechaza Orden B ingresando motivo obligatorio
      visit provider_order_path(order_b)

      sleep 1.5
      click_button "Rechazar"
      expect(page).to have_content("¿Rechazar el pedido PED-#{order_b.id}?")

      find("label", text: "Otro motivo").click
      fill_in "rejection-details", with: "Sin insumos para la preparación"

      click_button "Rechazar pedido"
      expect(page).to have_content("Pedido rechazado.")
      expect(order_b.reload.status).to eq("rejected")
      expect(order_b.rejection_reason).to eq("other")
      expect(order_b.rejection_details).to eq("Sin insumos para la preparación")

      sign_out

      # 1.4: Empleado verifica estados en Mis Órdenes
      sign_in consumer_user, role: :consumer
      visit orders_path

      # Orden A confirmada en Próximos
      expect(page).to have_content("Confirmado")

      # Orden B rechazada en Historial
      find("button", text: "Historial").click
      expect(page).to have_content("Rechazado")

      # Detalle de la Orden A como confirmado
      visit order_path(order_a)
      expect(page).to have_content("Confirmado")
    end
  end

  describe "Paso 2: Cancelación de pedido por el empleado (en plazo y fuera de plazo)" do
    let!(:order_c) do
      Order.create!(
        consumer:,
        schedule: sched_future,
        status: :pending,
        amount: 1,
        price: 300,
        discounted_price: 150,
        delivery_method: :office,
        address: "18 de Julio 1006"
      )
    end

    before do
      order_a.update!(status: :confirmed)
      sign_in consumer_user, role: :consumer
    end

    it "2.1 Permite cancelar un pedido futuro en plazo y registra el autor" do
      visit orders_path

      sleep 1.5
      within find("a[href='#{order_path(order_c)}']").ancestor("[data-slot='card']") do
        click_button "Cancelar"
      end

      expect(page).to have_content("¿Cancelar pedido?")
      click_button "Cancelar pedido"

      expect(page).to have_content("Pedido cancelado.")
      expect(order_c.reload.status).to eq("cancelled")
      expect(order_c.cancelled_by).to eq(consumer_user)
    end

    it "2.2 Deshabilita el botón de cancelación si el pedido está confirmado para hoy" do
      visit orders_path

      within find("a[href='#{order_path(order_a)}']").ancestor("[data-slot='card']") do
        expect(page).to have_button("Cancelar", disabled: true)
        expect(page).to have_content("Ya está confirmado para hoy, así que no se puede cancelar desde la app.")
      end
    end

    it "2.3 Bloquea bypass de interfaz al intentar cancelar fuera de plazo directamente" do
      expect(order_a.cancel(by: consumer_user)).to be(false)
      expect(order_a.reload.status).to eq("confirmed")
    end
  end

  describe "Paso 3: Cancelación por fuerza mayor por el proveedor" do
    before do
      order_a.update!(status: :confirmed)
    end

    it "cancela el pedido confirmado por causa del proveedor y actualiza la vista del empleado" do
      order_a.withdraw!(by: provider_user)

      expect(order_a.reload.status).to eq("cancelled")
      expect(order_a.cancelled_by).to eq(provider_user)

      sign_in consumer_user, role: :consumer
      visit orders_path

      find("button", text: "Historial").click
      expect(page).to have_content("Cancelado")
    end
  end

  describe "Paso 4: Modificación de disponibilidad (plato agotado) e impacto histórico" do
    before do
      order_a.update!(status: :confirmed)
    end

    it "bloquea nuevos pedidos sin alterar los pedidos y cobros ya confirmados" do
      sched_today.update!(available: false)

      sign_in consumer_user, role: :consumer
      visit dashboard_path

      find("button", text: /\b#{Date.current.day}\b/).click

      expect(page).to have_content("Agotado")
      expect(page).not_to have_button("Agregar #{milanesa.name}")

      # Integridad de datos y montos históricos de Orden A
      expect(order_a.reload.status).to eq("confirmed")
      expect(order_a.price).to eq(300)
      expect(order_a.discounted_price).to eq(150)
      expect(order_a.order_accounts.count).to be >= 1
    end
  end

  describe "Paso 5: Casos borde y consistencia de transiciones de estado" do
    before do
      order_a.update!(status: :confirmed)
      order_b.update!(status: :rejected, rejection_reason: :out_of_stock)
    end

    it "impide transiciones inválidas sobre pedidos ya confirmados o rechazados" do
      expect(order_a.decide(:confirmed)).to be(false)
      expect(order_a.decide(:rejected, reason: :out_of_stock)).to be(false)
      expect(order_b.decide(:confirmed)).to be(false)
    end

    it "valida que el rechazo requiera motivo y detalle cuando aplica" do
      new_order = Order.create!(
        consumer:,
        schedule: sched_future,
        status: :pending,
        amount: 1,
        price: 300,
        discounted_price: 150,
        delivery_method: :office,
        address: "18 de Julio 1006"
      )

      # Sin motivo: falla
      expect(new_order.decide(:rejected, reason: nil)).to be(false)
      expect(new_order.errors[:rejection_reason]).to be_present

      # Con motivo 'other' pero sin detalle: falla
      new_order.reload
      expect(new_order.decide(:rejected, reason: :other, details: "")).to be(false)
      expect(new_order.errors[:rejection_details]).to be_present

      # Con motivo 'other' y detalle: exitoso
      new_order.reload
      expect(new_order.decide(:rejected, reason: :other, details: "Sin ingredientes")).to be(true)
      expect(new_order.reload.status).to eq("rejected")
    end

    it "impide que un proveedor decida sobre pedidos de otro proveedor" do
      sign_in other_provider_user, role: :provider
      visit provider_order_path(order_a)

      expect(page).to have_no_content(order_a.menu.name)
      expect {
        other_provider_user.provider.orders.find(order_a.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
