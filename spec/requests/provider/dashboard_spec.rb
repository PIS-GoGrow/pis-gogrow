# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Dashboard", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :reviews, :admins, :accounts, :order_accounts, :payments

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  describe "GET /provider/dashboard" do
    context "sin sesión iniciada" do
      it "redirige al usuario a la pantalla de iniciar sesión" do
        get provider_dashboard_path

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "con rol de consumidor" do
      it "redirige a la raíz con alerta de acceso no autorizado" do
        sign_in users(:one), role: :consumer

        get provider_dashboard_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "con rol de admin" do
      it "redirige a la raíz con alerta de acceso no autorizado" do
        sign_in users(:admin), role: :admin

        get provider_dashboard_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "con rol de proveedor" do
      before do
        sign_in provider_user, role: :provider
      end

      it "responde exitosamente y renderiza el componente provider/dashboard/index" do
        get provider_dashboard_path

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("provider/dashboard/index")
      end

      it "envía las props exactas con los cálculos del día y mes actual" do
        provider.update!(order_deadline: Time.zone.parse("11:30"))

        get provider_dashboard_path

        expect(inertia).to have_props(
          today: I18n.l(Date.current, format: "%A, %-d de %B").capitalize,
          order_deadline: "11:30",
          provider: { order_deadline: "11:30" }
        )
      end

      context "con la hora de cierre configurada" do
        around do |example|
          travel_to(Time.current.change(hour: 12)) { example.run }
        end

        it "indica que la recepción sigue abierta antes de la hora de cierre" do
          provider.update!(order_deadline: Time.zone.parse("12:01"))

          get provider_dashboard_path

          expect(inertia).to have_props(order_deadline: "12:01", order_deadline_passed_today: false)
        end

        it "indica que la recepción está cerrada al llegar a la hora de cierre" do
          provider.update!(order_deadline: Time.zone.parse("12:00"))

          get provider_dashboard_path

          expect(inertia).to have_props(order_deadline: "12:00", order_deadline_passed_today: true)
        end
      end

      it "envía order_deadline como nil cuando no está configurada" do
        provider.update!(order_deadline: nil)

        get provider_dashboard_path

        expect(inertia).to have_props(
          order_deadline: nil,
          order_deadline_passed_today: false,
          provider: { order_deadline: nil }
        )
      end

      it "excluye pedidos cancelados y rechazados de las métricas del día" do
        today_schedule = schedules(:today)

        # Pedido rechazado para hoy
        Order.create!(
          consumer: consumers(:one),
          schedule: today_schedule,
          status: :rejected,
          delivery_method: :home,
          address: "Julio Herrera y Reissig 565",
          rejection_reason: :out_of_stock,
          amount: 1,
          price: 300.50,
          discounted_price: 150.25
        )

        # Pedido cancelado para hoy
        Order.create!(
          consumer: consumers(:one),
          schedule: today_schedule,
          status: :cancelled,
          delivery_method: :office,
          amount: 1,
          price: 300.50,
          discounted_price: 150.25
        )

        get provider_dashboard_path

        # upcoming_pending_today de fixtures tiene 1 pendiente a domicilio
        expect(inertia).to have_props(
          today_orders_count: 1,
          pending_orders_count: 1,
          office_orders_count: 0,
          home_orders_count: 1
        )
      end

      it "aisla los datos de otros proveedores en pedidos, menús y reseñas" do
        # Aseguramos que el otro proveedor tiene sus propios platos y reseñas
        other_provider = providers(:endulzate)
        expect(other_provider.menus.count).to be > 0

        get provider_dashboard_path

        # tuviandita solo tiene el menú milanesa en fixtures (sin reseñas)
        expect(inertia).to have_props(
          month_dishes_count: provider.menus.count,
          average_rating: nil
        )

        # Ahora agregamos una reseña para el plato del proveedor actual
        Review.create!(menu: menus(:milanesa), rating: 5, description: "Excelente")

        get provider_dashboard_path

        expect(inertia).to have_props(
          average_rating: 5.0
        )
      end
    end
  end
end
