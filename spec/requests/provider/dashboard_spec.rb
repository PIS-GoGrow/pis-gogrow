# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Dashboard", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :reviews, :admins, :accounts, :order_accounts, :payments

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  describe "GET /provider/inicio" do
    context "sin sesión iniciada" do
      it "redirige al usuario a la pantalla de iniciar sesión" do
        get provider_dashboard_path

        expect(response).to redirect_to(provider_sign_in_path)
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
          today: DateFormat.long(Date.current),
          order_deadline: "11:30",
          provider: { order_deadline: "11:30" }
        )
      end

      it "expone el progreso de completitud de la cuenta" do
        get provider_dashboard_path

        expect(inertia).to(have_props do |props|
          props["sections_total"] == 4 &&
            props["completed_sections_count"].is_a?(Integer)
        end)
      end

      it "refleja exactamente 0 secciones completadas cuando ningún timestamp está configurado" do
        provider.update_columns(
          payment_details_configured_at: nil,
          order_deadline_configured_at: nil,
          deliveries_configured_at: nil,
          notifications_configured_at: nil
        )

        get provider_dashboard_path

        expect(inertia).to have_props(completed_sections_count: 0, sections_total: 4)
      end

      it "refleja el conteo parcial (2/4) cuando dos secciones están configuradas" do
        provider.update_columns(
          payment_details_configured_at: Time.current,
          order_deadline_configured_at: nil,
          deliveries_configured_at: Time.current,
          notifications_configured_at: nil
        )

        get provider_dashboard_path

        expect(inertia).to have_props(completed_sections_count: 2, sections_total: 4)
      end

      it "refleja 4 secciones completadas cuando la cuenta está 100% configurada" do
        provider.update_columns(
          payment_details_configured_at: Time.current,
          order_deadline_configured_at: Time.current,
          deliveries_configured_at: Time.current,
          notifications_configured_at: Time.current
        )

        get provider_dashboard_path

        expect(inertia).to have_props(completed_sections_count: 4, sections_total: 4)
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
          month_dishes_count: 1,
          average_rating: nil,
          top_rated: []
        )

        # Ahora agregamos una reseña para el plato del proveedor actual
        Review.create!(menu: menus(:milanesa), rating: 5, description: "Excelente")

        get provider_dashboard_path

        expect(inertia).to have_props(
          average_rating: 5.0
        )
      end

      it "cuenta en los hallazgos del mes solo los platos pedidos y las reseñas escritas en el mes" do
        Menu.create!(provider:, name: "Wok de verduras", description: "Sin pedidos", price: 300)
        Review.create!(menu: menus(:milanesa), rating: 1, created_at: Date.current.prev_month.in_time_zone)
        Review.create!(menu: menus(:milanesa), rating: 4, created_at: Time.current)

        get provider_dashboard_path

        expect(inertia).to have_props(month_dishes_count: 1, average_rating: 4.0)
      end

      it "muestra en los hallazgos del mes los mismos números que Hallazgos para el mes actual" do
        get provider_insights_path
        insights = inertia.props.slice(:orders_count, :dishes_count, :average_rating)

        get provider_dashboard_path

        expect(inertia.props.slice(:month_orders_count, :month_dishes_count, :average_rating).values).to eq(insights.values)
      end

      it "expone los platos mejor valorados ordenados por promedio, sin las reseñas sin puntaje" do
        # milanesa: promedio 4.5
        Review.create!(menu: menus(:milanesa), rating: 4)
        Review.create!(menu: menus(:milanesa), rating: 5)

        wok = Menu.create!(provider:, name: "Wok de verduras", description: "Salteado de verduras", price: 150)
        Review.create!(menu: wok, rating: 5)
        # Una reseña sin puntaje no es una valoración: no cuenta para el promedio.
        Review.create!(menu: wok, rating: nil, description: "sin puntaje")

        get provider_dashboard_path

        expect(inertia.props[:top_rated]).to eq([
          { "name" => "Wok de verduras", "rating" => 5.0 },
          { "name" => "Milanesa con papas fritas", "rating" => 4.5 }
        ])
      end
    end
  end

  describe "notificaciones" do
    it "no muestra en la sesión de proveedor las notificaciones de empleado del mismo usuario" do
      user = users(:one)
      Provider.create!(user:, onboarding_completed_at: Time.current)
      configuration = Notification::Configuration.find_or_create_by!(key: "order_updates") do |record|
        record.roles = %w[consumer]
      end
      Notification.create!(
        notification_configuration: configuration,
        user:,
        role: "consumer",
        event: "order_confirmation",
        requires_action: false,
        notifiable: orders(:upcoming_pending_today),
        description_data: {date: "12/12", provider: "TuViandita"}
      )

      sign_in user, role: :provider
      get provider_dashboard_path

      expect(inertia.props[:notifications]).to be_empty
    end

    it "le muestra al proveedor el aviso cuando un empleado cancela un pedido confirmado" do
      order = orders(:upcoming_confirmed_future)
      order.cancel(by: order.consumer.user)

      sign_in provider_user, role: :provider
      get provider_dashboard_path

      expect(inertia.props[:notifications].pluck(:title)).to eq([ "Un pedido fue cancelado" ])
    end
  end
end
