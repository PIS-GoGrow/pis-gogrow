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

    it "redirects an admin to the home page" do
      user = User.create!(name: "Admin User", email: "admin-provider-orders@gogrow.com", password: "password123456")
      Admin.create!(user:, company: companies(:gogrow))
      sign_in user, role: :admin

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

    it "shows order details for a cancelled order" do
      sign_in users(:provider_user), role: :provider

      get provider_order_path(orders(:history_cancelled_future))

      expect(response).to have_http_status(:success)
      expect(inertia).to have_props { |props|
        props.deep_symbolize_keys.dig(:order, :status) == "cancelled"
      }
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

    it "rejects an admin session" do
      user = User.create!(name: "Admin User", email: "admin-confirm-order@gogrow.com", password: "password123456")
      Admin.create!(user:, company: companies(:gogrow))
      sign_in user, role: :admin

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

    it "redirects back to the order detail when deciding from the detail page" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch confirm_provider_order_path(order), headers: { "HTTP_REFERER" => provider_order_url(order) }

      expect(order.reload).to be_confirmed
      expect(response).to redirect_to(provider_order_url(order))
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
    it "redirects to sign in without a session" do
      patch reject_provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(sign_in_path)
      expect(orders(:upcoming_pending_today).reload).to be_pending
    end

    it "rejects a session with a different active role" do
      sign_in users(:one), role: :consumer

      patch reject_provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(root_path)
      expect(orders(:upcoming_pending_today).reload).to be_pending
    end

    it "rejects an admin session" do
      user = User.create!(name: "Admin User", email: "admin-reject-order@gogrow.com", password: "password123456")
      Admin.create!(user:, company: companies(:gogrow))
      sign_in user, role: :admin

      patch reject_provider_order_path(orders(:upcoming_pending_today))

      expect(response).to redirect_to(root_path)
      expect(orders(:upcoming_pending_today).reload).to be_pending
    end

    it "rejects a pending order with a valid reason" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order), params: { reason: "out_of_stock" }

      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("out_of_stock")
      expect(order.rejection_details).to be_nil
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.order_rejected"))
    end

    it "rejects a pending order with 'other' reason and details" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order), params: { reason: "other", details: "Cerrado por reformas" }

      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("other")
      expect(order.rejection_details).to eq("Cerrado por reformas")
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.order_rejected"))
    end

    it "refuses to reject without a reason and returns an error flash" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order)

      expect(order.reload).to be_pending
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expected_alert = "#{Order.human_attribute_name(:rejection_reason)} #{I18n.t('activerecord.errors.models.order.attributes.rejection_reason.blank')}"
      expect(inertia).to have_flash(alert: expected_alert)
    end

    it "refuses to reject with 'other' reason when details are missing" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order), params: { reason: "other", details: "" }

      expect(order.reload).to be_pending
      expect(response).to redirect_to(provider_orders_path)

      follow_redirect!
      expected_alert = "#{Order.human_attribute_name(:rejection_details)} #{I18n.t('activerecord.errors.models.order.attributes.rejection_details.blank')}"
      expect(inertia).to have_flash(alert: expected_alert)
    end

    it "redirects back to the order detail when rejecting from the detail page" do
      sign_in users(:provider_user), role: :provider
      order = orders(:upcoming_pending_today)

      patch reject_provider_order_path(order),
            params: { reason: "duplicate_order" },
            headers: { "HTTP_REFERER" => provider_order_url(order) }

      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("duplicate_order")
      expect(response).to redirect_to(provider_order_url(order))
    end

    it "leaves an order that is no longer pending as it was" do
      sign_in users(:provider_user), role: :provider
      order = orders(:history_cancelled_future)

      patch reject_provider_order_path(order), params: { reason: "out_of_stock" }

      expect(order.reload).to be_cancelled

      follow_redirect!
      expect(inertia).to have_flash(alert: I18n.t("validations.order_not_pending"))
    end

    it "responds with not found for an order of another provider" do
      sign_in users(:provider_user), role: :provider

      patch reject_provider_order_path(other_provider_order)

      expect(response).to have_http_status(:not_found)
      expect(other_provider_order.reload).to be_pending
    end
  end
end
