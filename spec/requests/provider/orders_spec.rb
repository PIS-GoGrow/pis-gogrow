# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::Orders", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

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

    it "lists only today's orders of the signed-in provider" do
      sign_in users(:provider_user), role: :provider

      get provider_orders_path

      expect(inertia).to render_component("provider/orders/index")
      expect(inertia).to have_props { |props|
        listed = props.deep_symbolize_keys[:orders]

        listed.pluck(:id) == [ orders(:upcoming_pending_today).id ] &&
          listed.first[:status] == "pending" &&
          listed.first[:amount] == 1 &&
          listed.first[:consumer_name] == "Test User" &&
          listed.first[:menu_name] == "Milanesa con papas fritas" &&
          listed.first[:address] == "Julio Herrera y Reissig 565"
      }
    end
  end
end
