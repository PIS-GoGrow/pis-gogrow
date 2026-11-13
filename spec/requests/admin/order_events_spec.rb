# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::OrderEvents", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :menus, :menu_option_groups, :schedules, :orders

  describe "GET /rrhh/auditoria" do
    it "redirects visitors to the sign in page" do
      get admin_order_events_path

      expect(response).to redirect_to(admin_welcome_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get admin_order_events_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects a provider to the home page" do
      sign_in users(:provider_user), role: :provider

      get admin_order_events_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      it "lists who changed each order, with which role and the previous and new values" do
        order = orders(:upcoming_pending_future)
        sign_in users(:one), role: :consumer
        patch cancel_consumer_order_path(order)

        sign_in users(:admin), role: :admin
        get admin_order_events_path

        expect(inertia).to render_component("admin/order_events/index")
        event = inertia.props[:events].sole
        expect(event).to include(
          order_id: order.id,
          actor_name: users(:one).name,
          role: "consumer",
          action: "cancelled",
          consumer_name: users(:one).name,
          changes: [ { field: "status", before: "Pendiente", after: "Cancelado" } ]
        )
        expect(event[:occurred_at]).to match(%r{\A\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}\z})
      end

      it "records the provider's confirmation and formats the economic changes" do
        order = orders(:upcoming_pending_today)
        sign_in users(:provider_user), role: :provider
        patch confirm_provider_order_path(order)
        order.reload.update!(discounted_price: 99.5)

        sign_in users(:admin), role: :admin
        get admin_order_events_path

        price_change, confirmation = inertia.props[:events]
        expect(confirmation).to include(action: "confirmed", role: "provider", actor_name: users(:provider_user).name)
        expect(price_change).to include(
          action: "price_changed",
          actor_name: nil,
          changes: [ { field: "discounted_price", before: Account.format_amount(order.discounted_price_before_last_save), after: "$99,50" } ]
        )
      end

      # IBP-038 CA1/CA2: la hora es la de Montevideo, no la UTC del servidor.
      it "shows the exact date and time of the change in Montevideo time" do
        travel_to Time.zone.local(2026, 10, 21, 22, 30, 15) do
          orders(:upcoming_pending_future).update!(notes: "Sin sal")
        end
        sign_in users(:admin), role: :admin

        get admin_order_events_path

        expect(inertia.props[:events].sole[:occurred_at]).to eq("21/10/2026 22:30:15")
      end

      it "leaves out the events of other companies" do
        other_company = Company.create!(name: "Otra", address: "Rivera 1234")
        OrderEvent.create!(order_id: 0, company: other_company, action: :created)
        orders(:upcoming_pending_future).update!(notes: "Sin sal")
        sign_in users(:admin), role: :admin

        get admin_order_events_path

        expect(inertia.props[:events].pluck(:order_id)).to eq([ orders(:upcoming_pending_future).id ])
      end

      it "filters by order, action, role, actor and date" do
        order = orders(:upcoming_pending_future)
        other = orders(:upcoming_confirmed_future)
        Current.session = users(:one).sessions.create!(role: :consumer)
        order.update!(notes: "Sin sal")
        Current.reset
        order.update!(price: 999)
        other.update!(notes: "Sin cebolla")
        sign_in users(:admin), role: :admin

        get admin_order_events_path, params: { order_id: "PED-#{order.id}" }
        expect(inertia.props[:events].pluck(:order_id).uniq).to eq([ order.id ])

        get admin_order_events_path, params: { event_action: "price_changed" }
        expect(inertia.props[:events].pluck(:action)).to eq([ "price_changed" ])

        get admin_order_events_path, params: { role: "consumer" }
        expect(inertia.props[:events].pluck(:order_id)).to eq([ order.id ])

        get admin_order_events_path, params: { actor: users(:one).name.upcase }
        expect(inertia.props[:events].pluck(:action)).to eq([ "modified" ])

        get admin_order_events_path, params: { from: Date.current.tomorrow.iso8601 }
        expect(inertia.props[:events]).to be_empty
        expect(inertia).to have_props(total: 0, filters: { from: Date.current.tomorrow.iso8601 })

        get admin_order_events_path, params: { event_action: "all", role: "all", from: "no es fecha" }
        expect(inertia.props[:total]).to eq(3)
      end
    end
  end

  it "offers no way to edit or delete an event" do
    orders(:upcoming_pending_future).update!(notes: "Sin sal")
    event = OrderEvent.sole
    sign_in users(:admin), role: :admin

    patch "/rrhh/auditoria/#{event.id}", params: { changeset: {} }
    delete "/rrhh/auditoria/#{event.id}"

    expect(event.reload.changeset).to eq("notes" => [ nil, "Sin sal" ])
  end
end
