# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::Orders", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  describe "GET /provider/orders" do
    it "redirects to sign in without a session" do
      get provider_orders_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to sign in" do
      sign_in users(:two), role: :consumer

      get provider_orders_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "lists only today's orders of the signed-in provider, newest first" do
      sign_in users(:one), role: :provider

      get provider_orders_path

      expect(inertia).to render_component("provider/orders/index")
      expect(inertia).to have_props(orders: [
        {
          id: orders(:confirmed_today).id,
          status: "confirmed",
          amount: 1,
          notes: nil,
          price: 300.0,
          time: "13:00",
          consumer_name: "Another User",
          menu_name: "Wok de verduras",
          address: "Oficina GoGrow"
        },
        {
          id: orders(:pending_today).id,
          status: "pending",
          amount: 2,
          notes: "Sin picante",
          price: 300.0,
          time: "12:30",
          consumer_name: "Another User",
          menu_name: "Wok de verduras",
          address: "Av. Brasil 2145"
        }
      ])
    end
  end
end
