# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Orders", type: :request do
  fixtures :orders, :schedules, :menus, :providers, :consumers, :companies, :users

  describe "GET /orders" do
    it "redirects visitors to the sign in page" do
      get orders_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects users without a consumer profile" do
      sign_in users(:provider_user)
      get orders_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as an employee" do
      before { sign_in users(:one) }

      it "renders the orders page" do
        get orders_path
        expect(inertia).to render_component("orders/index")
      end

      it "splits the employee's orders between upcoming and history" do
        get orders_path

        expect(inertia.props[:upcoming_orders].pluck(:id)).to contain_exactly(
          orders(:upcoming_pending_today).id,
          orders(:upcoming_pending_future).id,
          orders(:upcoming_confirmed_future).id
        )
        expect(inertia.props[:past_orders].pluck(:id)).to contain_exactly(
          orders(:history_cancelled_future).id,
          orders(:history_rejected_future).id,
          orders(:history_confirmed_past).id,
          orders(:history_pending_past).id,
          orders(:history_without_schedule).id
        )
      end

      it "exposes the data needed to follow an order" do
        get orders_path

        order = inertia.props[:upcoming_orders].find { |o| o[:id] == orders(:upcoming_confirmed_future).id }

        expect(order).to include(
          status: "confirmed",
          delivery_method: "office",
          menu_name: "Milanesa con papas fritas",
          provider_name: "Provider User",
          date: (Date.current + 3).iso8601,
          address: "18 de Julio 1006",
          price: 601.0,
          discounted_price: 300.50
        )
      end

      it "serializes orders left without a schedule" do
        get orders_path

        order = inertia.props[:past_orders].find { |o| o[:id] == orders(:history_without_schedule).id }

        expect(order).to include(date: nil, menu_name: nil, provider_name: nil, delivery_method: "home")
      end

      it "hides orders belonging to another employee" do
        get orders_path

        ids = inertia.props[:upcoming_orders].pluck(:id) + inertia.props[:past_orders].pluck(:id)
        expect(ids).not_to include(orders(:other_consumer_upcoming).id)
      end
    end
  end

  describe "GET /orders/:id" do
    it "redirects visitors to the sign in page" do
      get order_path(orders(:upcoming_confirmed_future))
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as an employee" do
      before { sign_in users(:one) }

      it "renders the detail page" do
        get order_path(orders(:upcoming_confirmed_future))
        expect(inertia).to render_component("orders/show")
      end

      it "exposes the breakdown the employee needs to check the order" do
        get order_path(orders(:upcoming_confirmed_future))

        expect(inertia.props[:order]).to include(
          status: "confirmed",
          delivery_method: "office",
          menu_name: "Milanesa con papas fritas",
          provider_name: "Provider User",
          date: (Date.current + 3).iso8601,
          address: "18 de Julio 1006",
          amount: 2,
          price: 601.0,
          subsidy: 300.50,
          discounted_price: 300.50
        )
      end

      it "does not expose another employee's order" do
        get order_path(orders(:other_consumer_upcoming))

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /orders" do
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    def setup_consumer
      company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
      user = User.create!(email: "order-consumer-#{SecureRandom.hex(4)}@gmail.com", name: "Sofía", password: "password123456")
      consumer = Consumer.create!(user:, company:, address: "Ellauri 1234")
      sign_in(user, role: :consumer)
      [ consumer, company ]
    end

    def create_schedule(price: 300, amount: 5)
      provider = Provider.find_or_create_by!(user: users(:two))
      menu = Menu.create!(provider:, name: "Milanesa", description: "Con puré", price:)
      Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount:)
    end

    it "creates the cart atomically with server prices, benefit and delivery address" do
      consumer, company = setup_consumer
      schedule = create_schedule
      Benefit.create!(consumer:, description: "Viandas mensuales", amount: 10, percentage: 50, due_date: 1.month.from_now)

      expect do
        post orders_path, params: {
          order: {
            address: company.address,
            items: [ { schedule_id: schedule.id, quantity: 2, notes: "Sin salsa" } ]
          }
        }
      end.to change(Order, :count).by(1)

      order = Order.last
      expect(response).to redirect_to(dashboard_confirmation_path(confirmed_order_ids: [ order.id ]))
      expect(order).to have_attributes(
        consumer:,
        schedule:,
        amount: 2,
        address: company.address,
        delivery_method: "office",
        price: 600.to_d,
        discounted_price: 300.to_d,
        notes: "Sin salsa"
      )
      expect(order).to be_pending
      expect(schedule.reload.remaining_amount).to eq(3)
      follow_redirect!
      expect(inertia).to render_component("consumer/dashboard/confirmation")
      expect(inertia).to have_flash(notice: I18n.t("flash.cart_confirmed"))
      expect(inertia).to have_props(total: 300.0)
      expect(inertia).to have_props({
        orders: [
          {
            id: order.id,
            date: Date.current.iso8601,
            address: company.address,
            delivery_method: "office",
            provider_name: users(:two).name,
            name: "Milanesa",
            quantity: 2,
            discounted_price: 300.0
          }
        ]
      })

      get dashboard_path
      expect(inertia).to have_props(
        benefit: {
          limit: 2,
          used: 2,
          percentage: 50,
          monthly_limit: 10,
          monthly_used: 2,
          monthly_remaining: 8
        }
      )
    end

    it "does not create a partial cart when one item is unavailable" do
      consumer, = setup_consumer
      available = create_schedule
      unavailable = create_schedule(amount: 1)
      Order.create!(consumer:, schedule: unavailable, amount: 1, price: unavailable.menu.price, address: consumer.address, delivery_method: :home)

      expect do
        post orders_path, params: {
          order: {
            address: consumer.address,
            items: [
              { schedule_id: available.id, quantity: 1 },
              { schedule_id: unavailable.id, quantity: 1 }
            ]
          }
        }
      end.not_to change(Order, :count)

      expect(response).to redirect_to(dashboard_path)
      expect(available.reload.remaining_amount).to eq(5)
      follow_redirect!
      expect(inertia).to have_props(errors: { order_error: I18n.t("validations.cart_unavailable") })
    end

    it "rejects an empty cart" do
      consumer, = setup_consumer

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [] } }
      end.not_to change(Order, :count)

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(inertia).to have_props(errors: { order_error: I18n.t("validations.empty_cart") })
    end

    it "creates multiple orders against existing schedules without creating schedules or payments" do
      consumer, = setup_consumer
      first = create_schedule
      second = create_schedule(price: 250)
      second.update!(date: Date.current + 1.day)

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [
          { schedule_id: first.id, quantity: 1 },
          { schedule_id: second.id, quantity: 2 }
        ] } }
      end.to change(Order, :count).by(2).and change(Schedule, :count).by(0).and change(Payment, :count).by(0)

      expect(consumer.orders.sum(:discounted_price)).to eq(800)
    end

    it "creates separate orders for different toppings of the same dish" do
      consumer, = setup_consumer
      schedule = create_schedule(amount: 3)

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [
          { schedule_id: schedule.id, quantity: 1, notes: "Ricota y nuez · Filetto" },
          { schedule_id: schedule.id, quantity: 1, notes: "Ricota y espinaca · Bolognesa" }
        ] } }
      end.to change(Order, :count).by(2)

      expect(schedule.reload.remaining_amount).to eq(1)
      expect(consumer.orders.order(:id).last(2).pluck(:notes)).to contain_exactly(
        "Ricota y nuez · Filetto",
        "Ricota y espinaca · Bolognesa"
      )
    end

    [ 0, -1, "1.5", "2abc" ].each do |quantity|
      it "rejects invalid quantity #{quantity}" do
        consumer, = setup_consumer
        schedule = create_schedule

        expect do
          post orders_path, params: { order: { address: consumer.address, items: [ { schedule_id: schedule.id, quantity: } ] } }
        end.not_to change(Order, :count)

        follow_redirect!
        expect(inertia).to have_props(errors: { order_error: I18n.t("validations.invalid_quantity") })
      end
    end

    it "rejects an address outside the employee profile" do
      setup_consumer
      schedule = create_schedule

      expect do
        post orders_path, params: { order: { address: "Otra dirección", items: [ { schedule_id: schedule.id, quantity: 1 } ] } }
      end.not_to change(Order, :count)

      follow_redirect!
      expect(inertia).to have_props(errors: { order_error: I18n.t("validations.invalid_address") })
    end

    it "rejects orders from a different active role" do
      consumer, = setup_consumer
      Provider.create!(user: consumer.user)
      consumer.user.reload
      consumer.user.sessions.last.update!(role: :provider)
      schedule = create_schedule

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [ { schedule_id: schedule.id, quantity: 1 } ] } }
      end.not_to change(Order, :count)

      expect(response).to redirect_to(root_path)
    end

    it "rejects past schedules" do
      consumer, = setup_consumer
      schedule = create_schedule
      schedule.update!(date: Date.yesterday)

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [ { schedule_id: schedule.id, quantity: 1 } ] } }
      end.not_to change(Order, :count)
    end

    it "delivers office-only providers to the office and other providers to the selected home" do
      consumer, company = setup_consumer
      office_only = create_schedule
      office_only.menu.provider.update!(home_delivery: false)
      home_provider = Provider.create!(user: consumer.user, home_delivery: true)
      home_menu = Menu.create!(provider: home_provider, name: "Ensalada", price: 250)
      home_schedule = Schedule.create!(menu: home_menu, date: Date.current, amount: 5)

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [
          { schedule_id: office_only.id, quantity: 1 },
          { schedule_id: home_schedule.id, quantity: 1 }
        ] } }
      end.to change(Order, :count).by(2)

      expect(consumer.orders.find_by!(schedule: office_only)).to have_attributes(address: company.address, delivery_method: "office")
      expect(consumer.orders.find_by!(schedule: home_schedule)).to have_attributes(address: consumer.address, delivery_method: "home")
      follow_redirect!
      expect(inertia).to render_component("consumer/dashboard/confirmation")
    end

    it "keeps office delivery when the employee selects the office" do
      consumer, company = setup_consumer
      schedule = create_schedule
      schedule.menu.provider.update!(home_delivery: false)

      post orders_path, params: { order: { address: company.address, items: [ { schedule_id: schedule.id, quantity: 1 } ] } }

      expect(consumer.orders.last.address).to eq(company.address)
    end

    it "rolls back the cart when an office-only provider has no office address" do
      consumer, company = setup_consumer
      company.update!(address: nil)
      schedule = create_schedule
      schedule.menu.provider.update!(home_delivery: false)

      expect do
        post orders_path, params: { order: { address: consumer.address, items: [ { schedule_id: schedule.id, quantity: 1 } ] } }
      end.not_to change(Order, :count)

      follow_redirect!
      expect(inertia).to have_props(errors: { order_error: I18n.t("validations.office_address_required") })
    end
  end
  describe "PATCH /orders/:id/cancel" do
    it "redirects visitors to the sign in page" do
      patch cancel_consumer_order_path(orders(:upcoming_pending_future))

      expect(response).to redirect_to(sign_in_path)
    end

    it "rejects a session with a different active role" do
      sign_in users(:provider_user), role: :provider

      patch cancel_consumer_order_path(orders(:upcoming_pending_future))

      expect(response).to redirect_to(root_path)
      expect(orders(:upcoming_pending_future).reload).to be_pending
    end

    context "when signed in as an employee" do
      before { sign_in users(:one) }

      it "cancels a pending order and moves it to the history" do
        order = orders(:upcoming_pending_future)

        patch cancel_consumer_order_path(order)

        expect(order.reload).to be_cancelled
        expect(response).to redirect_to(orders_path)

        follow_redirect!
        expect(inertia).to have_flash(notice: I18n.t("flash.order_cancelled"))
        expect(inertia.props[:past_orders].pluck(:id)).to include(order.id)
        expect(inertia.props[:upcoming_orders].pluck(:id)).not_to include(order.id)
      end

      it "cancels a confirmed order whose delivery day is still ahead" do
        order = orders(:upcoming_confirmed_future)

        patch cancel_consumer_order_path(order)

        expect(order.reload).to be_cancelled
        expect(order.cancelled_by).to eq(users(:one))
      end

      it "refuses to cancel a confirmed order on its delivery day" do
        order = orders(:upcoming_pending_today)
        order.update!(status: :confirmed)

        patch cancel_consumer_order_path(order)

        expect(order.reload).to be_confirmed

        follow_redirect!
        expect(inertia).to have_flash(alert: I18n.t("validations.order_not_cancellable"))
      end

      it "refuses a direct request against a pending order whose delivery day already passed" do
        order = orders(:history_pending_past)

        patch cancel_consumer_order_path(order)

        expect(order.reload).to be_pending

        follow_redirect!
        expect(inertia).to have_flash(alert: I18n.t("validations.order_not_cancellable"))
      end

      it "does not cancel another employee's order" do
        order = orders(:other_consumer_upcoming)

        patch cancel_consumer_order_path(order)

        expect(response).to have_http_status(:not_found)
        expect(order.reload).to be_confirmed
      end
    end
  end
end
