# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer cart and orders lifecycle", type: :request do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules,
           :benefit_configurations, :benefits, :orders

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:admin_user) { users(:admin) }
  let(:schedule) { schedules(:today) }
  let(:company_address) { companies(:gogrow).address }

  describe "Control de acceso por rol en /dashboard y POST /orders" do
    it "redirige al inicio de sesión cuando un visitante no autenticado intenta acceder a /dashboard" do
      get dashboard_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirige al inicio de sesión cuando un visitante no autenticado intenta enviar un carrito a POST /orders" do
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: schedule.id, quantity: 1, notes: "", options: [] } ]
        }
      }
      expect(response).to redirect_to(sign_in_path)
    end

    it "rechaza el acceso a /dashboard para usuarios con rol provider redirigiendo a la raíz" do
      sign_in provider_user, role: :provider
      get dashboard_path
      expect(response).to redirect_to(root_path)
    end

    it "rechaza POST /orders para usuarios con rol provider redirigiendo a la raíz" do
      sign_in provider_user, role: :provider
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: schedule.id, quantity: 1, notes: "", options: [] } ]
        }
      }
      expect(response).to redirect_to(root_path)
    end

    it "rechaza el acceso a /dashboard para usuarios con rol admin redirigiendo a la raíz" do
      sign_in admin_user, role: :admin
      get dashboard_path
      expect(response).to redirect_to(root_path)
    end

    it "rechaza POST /orders para usuarios con rol admin redirigiendo a la raíz" do
      sign_in admin_user, role: :admin
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: schedule.id, quantity: 1, notes: "", options: [] } ]
        }
      }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /dashboard props exactas de Inertia" do
    before do
      sign_in consumer_user, role: :consumer
    end

    it "renderiza el componente de dashboard del consumidor con props estructuradas para el carrito" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("consumer/dashboard/index")

      expect(inertia.props).to include(:week, :schedules, :benefit, :addresses)
      expect(inertia.props[:week]).to include(:start_date, :end_date, :days)
      expect(inertia.props[:schedules]).to be_an(Array)
      expect(inertia.props[:benefit]).to include(:percentage, :monthly_remaining)
      expect(inertia.props[:addresses]).to be_an(Array)

      if inertia.props[:schedules].any?
        first_schedule = inertia.props[:schedules].first
        expect(first_schedule).to include(
          :id,
          :date,
          :remaining,
          :sold_out,
          :orders_closed,
          :menu
        )
        expect(first_schedule[:menu]).to include(
          :id,
          :name,
          :price,
          :provider_name,
          :home_delivery
        )
      end
    end
  end

  describe "Bypass de interfaz y tipos de datos inesperados en POST /orders" do
    before do
      sign_in consumer_user, role: :consumer
    end

    it "rechaza un carrito vacío enviado directamente por API y redirige con error" do
      post orders_path, params: {
        order: {
          address: company_address,
          items: []
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.empty_cart"))
    end

    it "rechaza cantidades no numéricas (string) enviadas directo al endpoint" do
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: schedule.id, quantity: "dos", notes: "", options: [] } ]
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.invalid_quantity"))
    end

    it "rechaza cantidades flotantes o negativas en el payload" do
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: schedule.id, quantity: -2, notes: "", options: [] } ]
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.invalid_quantity"))
    end

    it "rechaza un schedule_id inexistente o manipulado" do
      post orders_path, params: {
        order: {
          address: company_address,
          items: [ { schedule_id: 999_999, quantity: 1, notes: "", options: [] } ]
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.cart_unavailable"))
    end

    it "rechaza una dirección de entrega no válida sin número de puerta" do
      post orders_path, params: {
        order: {
          address: "DireccionSinNumeroDePuerta",
          items: [ { schedule_id: schedule.id, quantity: 1, notes: "", options: [] } ]
        }
      }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.invalid_address"))
    end
  end

  describe "Integridad en la base de datos y rollback atómico del carrito" do
    before do
      sign_in consumer_user, role: :consumer
    end

    it "no persiste órdenes parciales si uno de los platos del carrito falla por falta de stock" do
      sold_out_schedule = Schedule.create!(
        menu: menus(:office_menu),
        date: schedule.date,
        amount: 0
      )

      expect {
        post orders_path, params: {
          order: {
            address: company_address,
            items: [
              { schedule_id: schedule.id, quantity: 1, notes: "", options: [] },
              { schedule_id: sold_out_schedule.id, quantity: 1, notes: "", options: [] }
            ]
          }
        }
      }.not_to change(Order, :count)

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia.props.dig(:errors, :order_error)).to eq(I18n.t("validations.insufficient_stock"))
    end

    it "crea las órdenes atómicamente cuando el carrito es válido y redirige a la confirmación" do
      expect {
        post orders_path, params: {
          order: {
            address: company_address,
            items: [
              { schedule_id: schedule.id, quantity: 1, notes: "Sin cubiertos", options: [] }
            ]
          }
        }
      }.to change(Order, :count).by(1)

      created_order = Order.last
      expect(response).to redirect_to(dashboard_confirmation_path(confirmed_order_ids: [ created_order.id ]))

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("consumer/dashboard/confirmation")
      expect(inertia.props[:orders].pluck(:id)).to include(created_order.id)
    end
  end

  # IBP-037: el subsidio especial se suma al base al confirmar el carrito.
  describe "POST /orders con subsidios especiales" do
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:consumer) { consumers(:one) }
    let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa", description: "Con puré", price: 300) }
    let(:wednesday) { Schedule.create!(menu:, date: Date.new(2026, 9, 16), amount: 10) }
    let(:thursday) { Schedule.create!(menu:, date: Date.new(2026, 9, 17), amount: 10) }
    let!(:base) do
      consumer.benefits.destroy_all
      consumer.benefits.create!(
        benefit_configuration: benefit_configurations(:monthly), percentage: 50, amount: 1, due_date: Date.new(2026, 9, 30)
      )
    end
    let!(:special) do
      consumer.benefits.create!(benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 30, amount: 2)
    end

    before { sign_in consumer_user, role: :consumer }

    def order_cart(*items)
      post orders_path, params: {
        order: {
          address: company_address,
          items: items.map { |schedule, quantity| { schedule_id: schedule.id, quantity:, notes: "", options: [] } }
        }
      }
    end

    it "descuenta el base y el especial y registra cuántas viandas cubrió cada uno" do
      order_cart([ wednesday, 3 ])

      order = Order.last
      # 1ª con 80% (60), 2ª solo con el premio (210), 3ª a precio completo.
      expect(order).to have_attributes(price: 900, discounted_price: 570)
      expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ base.id, 1 ], [ special.id, 2 ])
      follow_redirect!
      expect(inertia).to have_props(total: 570.0)
    end

    it "reparte los usos del especial sobre los primeros platos del carrito" do
      order_cart([ wednesday, 1 ], [ thursday, 2 ])

      first, second = consumer.orders.where(schedule: [ wednesday, thursday ]).order(:id)
      expect(first.discounted_price).to eq(60)
      expect(second.discounted_price).to eq(510)
      expect(second.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ special.id, 1 ])
    end

    it "no bloquea el pedido cuando supera los usos del especial" do
      special.update!(amount: 1)
      OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: special, benefit_used: 1)

      expect { order_cart([ wednesday, 2 ]) }.to change(Order, :count).by(1)
      expect(Order.last.discounted_price).to eq(450)
    end

    it "ignora un discounted_price o benefits manipulados en el payload y calcula el precio en el servidor" do
      post orders_path, params: {
        order: {
          address: company_address,
          discounted_price: 1.0,
          benefits: { special.id => 10 },
          items: [ { schedule_id: wednesday.id, quantity: 1, notes: "", options: [] } ]
        }
      }

      order = Order.last
      expect(order.discounted_price).to eq(60)
      expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ base.id, 1 ], [ special.id, 1 ])
    end
  end
end
