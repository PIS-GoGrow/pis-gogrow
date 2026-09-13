# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders", type: :request do
  fixtures :orders, :schedules, :menus, :providers, :consumers, :companies, :users

  describe "GET /orders" do
    it "redirects visitors to the sign in page" do
      get orders_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects users without a consumer profile" do
      sign_in users(:two)
      get orders_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects providers" do
      sign_in users(:provider_user)
      get orders_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as an employee" do
      before { sign_in users(:consumer_user) }

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
          menu_name: "Milanesa con papas fritas",
          provider_name: "Provider User",
          date: (Date.current + 3).iso8601,
          address: "Julio Herrera y Reissig 565",
          price: 601.0,
          discounted_price: 300.50
        )
      end

      it "serializes orders left without a schedule" do
        get orders_path

        order = inertia.props[:past_orders].find { |o| o[:id] == orders(:history_without_schedule).id }

        expect(order).to include(date: nil, menu_name: nil, provider_name: nil)
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
      before { sign_in users(:consumer_user) }

      it "renders the detail page" do
        get order_path(orders(:upcoming_confirmed_future))
        expect(inertia).to render_component("orders/show")
      end

      it "exposes the breakdown the employee needs to check the order" do
        get order_path(orders(:upcoming_confirmed_future))

        expect(inertia.props[:order]).to include(
          status: "confirmed",
          menu_name: "Milanesa con papas fritas",
          provider_name: "Provider User",
          date: (Date.current + 3).iso8601,
          address: "Julio Herrera y Reissig 565",
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
end
