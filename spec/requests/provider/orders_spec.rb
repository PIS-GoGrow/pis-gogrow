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

    it "lists only today's orders of the signed-in provider" do
      other_provider_order
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

  describe "PATCH /provider/orders/:id/confirm" do
    it "redirects to sign in without a session" do
      patch confirm_provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(sign_in_path)
      expect(orders(:upcoming_pending_today).reload).to be_pending
    end

    it "rejects a session with a different active role" do
      sign_in users(:one), role: :consumer

      patch confirm_provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(root_path)
      expect(orders(:upcoming_pending_today).reload).to be_pending
    end

    it "confirms a pending order" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch confirm_provider_order_path(order)

      expect(order.reload).to be_confirmed
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.order_confirmed"))
    end

    it "leaves an order that is no longer pending as it was" do
      sign_in users(:provider_user), role: :provider
      order = orders(:history_cancelled_future)

      patch confirm_provider_order_path(order)

      expect(order.reload).to be_cancelled

      follow_redirect!
      expect(inertia).to have_flash(alert: I18n.t("validations.order_not_pending"))
    end

    it "responds with not found for an order of another provider" do
      sign_in users(:provider_user), role: :provider

      patch confirm_provider_order_path(other_provider_order)

      expect(response).to have_http_status(:not_found)
      expect(other_provider_order.reload).to be_pending
    end
  end

  describe "PATCH /provider/orders/:id/reject" do
    it "rejects a pending order" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order)

      expect(order.reload).to be_rejected
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.order_rejected"))
    end

    it "responds with not found for an order of another provider" do
      sign_in users(:provider_user), role: :provider

      patch reject_provider_order_path(other_provider_order)

      expect(response).to have_http_status(:not_found)
      expect(other_provider_order.reload).to be_pending
    end
  end
end
