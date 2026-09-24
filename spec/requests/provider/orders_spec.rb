# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::Orders", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  # El pedido del otro proveedor se crea acá y no en los fixtures: los specs de
  # "Mis pedidos" cuentan órdenes y una fila más les cambiaría las listas.
  let(:other_provider_order) do
    Order.create!(
      consumer: consumers(:other),
      schedule: schedules(:sorrentinos_today),
      status: :pending,
      delivery_method: :office,
      amount: 1,
      price: 320.00,
      discounted_price: 160.00
    )
  end

  describe "GET /provider/orders" do
    it "redirects to sign in without a session" do
      get provider_orders_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get provider_orders_path

      expect(response).to redirect_to(root_path)
    end

    it "lists today's and future orders of the signed-in provider" do
      other_provider_order
      sign_in users(:provider_user), role: :provider

      get provider_orders_path

      expect(inertia).to render_component("provider/orders/index")

      listed = inertia.props.deep_symbolize_keys[:orders]

      expect(listed.pluck(:id)).to match_array(
        %i[
          upcoming_pending_today
          upcoming_pending_future
          upcoming_confirmed_future
          history_cancelled_future
          history_rejected_future
          other_consumer_upcoming
        ].map { |name| orders(name).id }
      )

      today = listed.find { |o| o[:id] == orders(:upcoming_pending_today).id }
      expect(today).to include(
        status: "pending",
        amount: 1,
        consumer_name: "Test User",
        menu_name: "Milanesa con papas fritas",
        address: "Julio Herrera y Reissig 565",
        delivery_date: "hoy"
      )
    end

    it "orders orders by delivery date ascending and creation time descending" do
      sign_in users(:provider_user), role: :provider

      older_today = orders(:upcoming_pending_today)
      older_today.update!(created_at: 2.hours.ago)

      newer_today = Order.create!(
        consumer: consumers(:one),
        schedule: schedules(:today),
        status: :pending,
        delivery_method: :home,
        amount: 1,
        price: 300.50,
        discounted_price: 150.25,
        address: "Julio Herrera y Reissig 565",
        created_at: 5.minutes.ago
      )

      tomorrow_schedule = Schedule.create!(
        menu: menus(:milanesa),
        date: Date.current + 1.day,
        amount: 5
      )
      order_tomorrow = Order.create!(
        consumer: consumers(:one),
        schedule: tomorrow_schedule,
        status: :pending,
        delivery_method: :home,
        amount: 1,
        price: 300.50,
        discounted_price: 150.25,
        address: "Julio Herrera y Reissig 565",
        created_at: 1.minute.ago
      )

      get provider_orders_path

      expect(inertia).to render_component("provider/orders/index")

      listed = inertia.props.deep_symbolize_keys[:orders]
      ids = listed.pluck(:id)

      expect(ids.index(newer_today.id)).to be < ids.index(older_today.id)
      expect(ids.index(older_today.id)).to be < ids.index(order_tomorrow.id)
      expect(ids.index(order_tomorrow.id)).to be < ids.index(orders(:upcoming_pending_future).id)
    end

    it "excludes past orders, orders without schedule, and orders of other providers" do
      other_provider_order
      sign_in users(:provider_user), role: :provider

      get provider_orders_path

      listed = inertia.props.deep_symbolize_keys[:orders]
      ids = listed.pluck(:id)

      expect(ids).not_to include(
        orders(:history_confirmed_past).id,
        orders(:history_pending_past).id,
        orders(:history_without_schedule).id,
        other_provider_order.id
      )
    end
  end

  describe "GET /provider/orders/:id" do
    it "redirects to sign in without a session" do
      get provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(sign_in_path)
    end

    it "shows what the provider needs to prepare the order" do
      sign_in users(:provider_user), role: :provider

      get provider_order_path(orders(:upcoming_pending_today))

      expect(inertia).to render_component("provider/orders/show")
      expect(inertia).to have_props { |props|
        order = props.deep_symbolize_keys[:order]

        order[:id] == orders(:upcoming_pending_today).id &&
          order[:status] == "pending" &&
          order[:amount] == 1 &&
          order[:date] == Date.current.iso8601 &&
          order[:consumer_name] == "Test User" &&
          order[:consumer_email] == "one@example.com" &&
          order[:consumer_company] == "GoGrow" &&
          order[:menu_name] == "Milanesa con papas fritas" &&
          order[:menu_description] == "Opción de carne o pollo" &&
          order[:discounted_price] == 150.25 &&
          order[:subsidy] == 150.25 &&
          order[:schedule_amount] == 5 &&
          order[:remaining_amount] == 4
      }
    end

    it "lists the menu options the provider has to prepare" do
      sign_in users(:other_provider_user), role: :provider

      get provider_order_path(other_provider_order)

      expect(inertia).to have_props { |props|
        order = props.deep_symbolize_keys[:order]

        order[:menu_sauces] == [ "Filetto", "Bolognesa" ] &&
          order[:menu_fillings] == [ "Ricota y nuez" ]
      }
    end

    it "responds with not found for an order of another provider" do
      sign_in users(:provider_user), role: :provider

      get provider_order_path(other_provider_order)

      expect(response).to have_http_status(:not_found)
    end
  end
end
