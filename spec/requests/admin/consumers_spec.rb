# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Consumers", type: :request do
  fixtures :users, :admins, :consumers, :companies, :orders, :schedules, :menus, :providers,
    :benefits, :benefit_configurations, :benefit_rules, :accounts, :payments, :order_accounts

  # Un empleado de otra empresa: no tiene que aparecer nunca en la de este admin.
  let!(:outsider) do
    company = Company.create!(name: "Otra empresa", address: "Rivera 2000")
    user = User.create!(email: "outsider@gmail.com", name: "Zoe Outsider", password: "password123456")
    Consumer.create!(user:, company:, address: "Rivera 2001")
  end

  describe "GET /admin/empleados" do
    it "redirects visitors to the sign in page" do
      get admin_consumers_path
      expect(response).to redirect_to(sign_in_path)

      get admin_consumers_path, params: { month: "2026-09", filter: "pending" }
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects users without an admin profile" do
      sign_in users(:one)
      get admin_consumers_path
      expect(response).to redirect_to(root_path)

      get admin_consumers_path, params: { month: "2026-09", filter: "pending" }
      expect(response).to redirect_to(root_path)
    end

    it "redirects providers even when month parameters are supplied" do
      sign_in users(:provider_user), role: :provider
      get admin_consumers_path, params: { month: "2026-09", filter: "pending" }
      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "renders the consumers page" do
        get admin_consumers_path
        expect(inertia).to render_component("admin/consumers/index")
      end

      it "lists only the employees of the admin's company" do
        get admin_consumers_path
        expect(inertia.props[:consumers].pluck(:id)).to contain_exactly(consumers(:one).id, consumers(:other).id)
      end

      it "summarizes the current month of each employee with the status that needs attention most" do
        get admin_consumers_path

        expect(inertia.props[:consumers]).to include(
          hash_including(id: consumers(:one).id, name: "Test User", amount: 950.75, status: "pending"),
          hash_including(id: consumers(:other).id, amount: 150.25, status: "submitted")
        )
      end

      it "opens on the filter the URL asks for, so the home can link to the pending ones" do
        get admin_consumers_path, params: { filter: "pending" }

        expect(inertia).to have_props(filter: "pending")
      end

      # El ranking del inicio se calcula con el mes elegido y su chevron trae ese mes.
      it "summarizes the month the URL asks for" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: consumers(:other), provider: providers(:tuviandita), month: previous, amount: 80)

        get admin_consumers_path, params: { filter: "pending", month: previous.strftime("%Y-%m") }

        expect(inertia.props[:consumers]).to include(
          hash_including(id: consumers(:one).id, amount: 0.0, status: nil),
          hash_including(id: consumers(:other).id, amount: 80.0, status: "pending")
        )
      end

      it "sends the month it summarizes and the months to choose from" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: consumers(:other), provider: providers(:tuviandita), month: previous, amount: 80)

        get admin_consumers_path, params: { month: previous.strftime("%Y-%m") }

        expect(inertia).to have_props(month: previous.strftime("%Y-%m"), current_month: Date.current.strftime("%Y-%m"))
        expect(inertia.props[:months].pluck(:key)).to include(previous.strftime("%Y-%m"), Date.current.strftime("%Y-%m"))
      end

      it "sends the current month when the URL asks for none" do
        get admin_consumers_path

        expect(inertia).to have_props(month: Date.current.strftime("%Y-%m"))
      end

      it "summarizes the current month with an invalid or future month" do
        [ "agosto", "2026-13", (Date.current + 2.months).strftime("%Y-%m") ].each do |month|
          get admin_consumers_path, params: { month: }

          expect(inertia).to have_props(month: Date.current.strftime("%Y-%m"), current_month: Date.current.strftime("%Y-%m"))
          expect(inertia.props[:consumers]).to include(
            hash_including(id: consumers(:one).id, amount: 950.75, status: "pending")
          )
        end
      end

      it "falls back to the current month when given an empty or whitespace month" do
        [ "", "   " ].each do |month|
          get admin_consumers_path, params: { month: }

          expect(inertia).to have_props(month: Date.current.strftime("%Y-%m"))
        end
      end

      it "formats all month options with year-month keys and localized labels" do
        get admin_consumers_path

        months = inertia.props[:months]
        expect(months).not_to be_empty
        expect(months).to all(
          match(
            key: a_string_matching(/\A\d{4}-\d{2}\z/),
            label: a_string_matching(/\A[a-zñáéíóú]+\s+\d{4}\z/i)
          )
        )
      end

      it "keeps the filter and month synchronized when both are requested" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: consumers(:other), provider: providers(:tuviandita), month: previous, amount: 80)

        get admin_consumers_path, params: { filter: "pending", month: previous.strftime("%Y-%m") }

        expect(inertia).to have_props(filter: "pending", month: previous.strftime("%Y-%m"))
      end

      it "never includes consumers of another company when querying a previous month" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: outsider, provider: providers(:tuviandita), month: previous, amount: 500)

        get admin_consumers_path, params: { month: previous.strftime("%Y-%m") }

        expect(inertia.props[:consumers].pluck(:id)).not_to include(outsider.id)
      end

      it "sends the photo of each employee" do
        users(:one).update!(avatar_url: "https://foto.example/one.jpg")

        get admin_consumers_path

        expect(inertia.props[:consumers]).to include(
          hash_including(id: consumers(:one).id, avatar_url: "https://foto.example/one.jpg"),
          hash_including(id: consumers(:other).id, avatar_url: nil)
        )
      end

      it "opens on every employee without a filter or with an unknown one" do
        get admin_consumers_path
        expect(inertia).to have_props(filter: "all")

        get admin_consumers_path, params: { filter: "everyone" }
        expect(inertia).to have_props(filter: "all")
      end

      # El diseño tiene solo Todos y Pendientes: Completados ya no es una pestaña.
      it "opens on every employee when the URL asks for the completed ones" do
        get admin_consumers_path, params: { filter: "completed" }

        expect(inertia).to have_props(filter: "all")
      end
    end
  end

  describe "GET /admin/empleados/:id" do
    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "renders the consumer's centralized detail" do
        get admin_consumer_path(consumers(:one))

        expect(inertia).to render_component("admin/consumers/show")
        expect(inertia.props[:consumer]).to include(name: "Test User", email: "one@example.com", company_name: "GoGrow")
        expect(inertia.props[:summary]).to include(amount: 950.75, status: "pending", meals_limit: 20)
        expect(inertia).to have_props(benefit_summary: { total: 50, base: 50, specials: [] })
      end

      it "groups the consumption history by month with its providers and confirmed orders" do
        get admin_consumer_path(consumers(:one))

        month = inertia.props[:months].sole
        expect(month).to include(amount: 950.75, status: "pending")
        expect(month[:providers].pluck(:name, :status)).to contain_exactly(
          [ "Provider User", "rejected" ], [ "Other Provider User", "pending" ]
        )
        expect(month[:orders].pluck(:id)).to contain_exactly(
          orders(:upcoming_confirmed_future).id, orders(:history_confirmed_past).id
        )
      end

      # Sin publicación, el pedido conserva su fecha de entrega: no se muestra el
      # día en que se hizo, que es lo que veía antes RR. HH. y no coincidía con Cobros.
      it "dates each order by its delivery even without its publication" do
        order = orders(:history_confirmed_past)
        delivery = order.schedule.date
        order.update_columns(schedule_id: nil, delivery_date: delivery, created_at: delivery - 2.days)

        get admin_consumer_path(consumers(:one))

        dates = inertia.props[:months].sole[:orders].to_h { [ it[:id], it[:date] ] }
        expect(dates[order.id]).to eq(delivery.strftime("%-d/%-m"))
      end

      it "shows the active benefit percentage" do
        get admin_consumer_path(consumers(:one))

        expect(inertia).to have_props(benefit_summary: { total: 50, base: 50, specials: [] })
      end

      # IBP-037: la ficha suma los subsidios especiales vigentes al base y los
      # desglosa con el nombre que les puso RRHH.
      it "adds the special subsidies in force to the base benefit" do
        consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:seniority), description: "Antigüedad (5 años)", percentage: 25
        )

        get admin_consumer_path(consumers(:one))

        expect(inertia).to have_props(
          benefit_summary: { total: 75, base: 50, specials: [ { name: "Antigüedad (5 años)", percentage: 25 } ] }
        )
      end

      it "sends no benefit summary for an employee without benefits" do
        consumers(:one).benefits.destroy_all

        get admin_consumer_path(consumers(:one))

        expect(inertia).to have_props(benefit_summary: nil)
      end

      it "does not show an employee of another company" do
        get admin_consumer_path(outsider)

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for an invalid or non-existent consumer id" do
        get admin_consumer_path(id: "invalid-id")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not signed in as HR" do
      it "redirects visitors without a session to the sign in page" do
        get admin_consumer_path(consumers(:one))

        expect(response).to redirect_to(sign_in_path)
      end

      it "redirects consumers to the root page" do
        sign_in users(:one), role: :consumer

        get admin_consumer_path(consumers(:one))

        expect(response).to redirect_to(root_path)
      end

      it "redirects providers to the root page" do
        sign_in users(:provider_user), role: :provider

        get admin_consumer_path(consumers(:one))

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
