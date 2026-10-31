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
      expect(response).to redirect_to(admin_welcome_path)

      get admin_consumers_path, params: { month: "2026-09", filter: "pending" }
      expect(response).to redirect_to(admin_welcome_path)
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

      # Lo que el empleado dejó sin pagar de meses anteriores también es deuda:
      # mirando solo el mes actual, RR. HH. no lo veía.
      it "adds what the employee still owes from earlier months" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: consumers(:other), provider: providers(:tuviandita), month: previous, amount: 80)

        get admin_consumers_path

        expect(inertia.props[:consumers]).to include(
          hash_including(id: consumers(:other).id, amount: 230.25, status: "pending")
        )
      end

      it "leaves out earlier months that were already paid" do
        previous = 1.month.ago.to_date.beginning_of_month
        paid = Account.create!(owner: consumers(:other), provider: providers(:tuviandita), month: previous, amount: 80)
        paid.payments.create!(provider: providers(:tuviandita), status: :approved)

        get admin_consumers_path

        expect(inertia.props[:consumers]).to include(
          hash_including(id: consumers(:other).id, amount: 150.25, status: "submitted")
        )
      end

      it "never includes the debt of another company's employees" do
        previous = 1.month.ago.to_date.beginning_of_month
        Account.create!(owner: outsider, provider: providers(:tuviandita), month: previous, amount: 500)

        get admin_consumers_path

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

        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        expect(month).to include(amount: 950.75, status: "pending")
        expect(month[:providers].pluck(:id)).to contain_exactly(providers(:tuviandita).id, providers(:endulzate).id)
        expect(month[:providers].pluck(:name, :status)).to contain_exactly(
          [ "Provider User", "rejected" ], [ "Other Provider User", "pending" ]
        )
        expect(month[:orders].pluck(:id)).to contain_exactly(
          orders(:upcoming_confirmed_future).id, orders(:history_confirmed_past).id
        )
        expect(month[:orders].pluck(:provider_id)).to contain_exactly(providers(:tuviandita).id, providers(:tuviandita).id)
      end

      it "sends the current year from the current month to January and fills months without consumption" do
        get admin_consumer_path(consumers(:one))

        current_year = Date.current.year
        months = inertia.props[:months].select { it[:year] == current_year }

        expect(months.pluck(:key)).to eq(
          Date.current.month.downto(1).map { |month| format("%<year>d-%<month>02d", year: current_year, month:) }
        )

        empty_months = months.reject { it[:key] == Date.current.strftime("%Y-%m") }
        expect(empty_months).to all(
          include(amount: 0.0, subsidy: 0.0, status: nil, providers: [], orders: [])
        )
      end

      it "puts the current year first and includes complete previous years with consumption" do
        previous_year = Date.current.year - 1
        consumers(:one).accounts.create!(
          provider: providers(:tuviandita),
          month: Date.new(previous_year, 5, 1),
          amount: 150
        )

        get admin_consumer_path(consumers(:one))

        months = inertia.props[:months]
        expect(months.pluck(:year).uniq).to eq([ Date.current.year, previous_year ])
        expect(months.count { it[:year] == previous_year }).to eq(12)
      end

      # Sin publicación, el pedido conserva su fecha de entrega: no se muestra el
      # día en que se hizo, que es lo que veía antes RR. HH. y no coincidía con Cobros.
      it "dates each order by its delivery even without its publication" do
        order = orders(:history_confirmed_past)
        delivery = order.schedule.date
        order.update_columns(schedule_id: nil, delivery_date: delivery, created_at: delivery - 2.days)

        get admin_consumer_path(consumers(:one))

        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        dates = month[:orders].to_h { [ it[:id], it[:date] ] }
        expect(dates[order.id]).to eq(I18n.l(delivery, format: "%-d/%-m"))
      end

      it "sorts confirmed orders in consumption history from the newest delivery, as in the design" do
        earlier = orders(:history_confirmed_past)
        later = orders(:upcoming_confirmed_future)

        earlier.update_columns(created_at: Time.current)
        later.update_columns(created_at: 10.days.ago)

        get admin_consumer_path(consumers(:one))

        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        orders_in_month = month[:orders]
        expect(orders_in_month.pluck(:id)).to eq([ later.id, earlier.id ])
      end

      it "handles orders with nil delivery dates without 500 exceptions" do
        order = orders(:history_confirmed_past)
        order.update_columns(delivery_date: nil, schedule_id: nil)

        get admin_consumer_path(consumers(:one))

        expect(response).to have_http_status(:ok)
        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        order_prop = month[:orders].find { it[:id] == order.id }
        expect(order_prop[:date]).to eq(I18n.l(order.created_at.to_date, format: "%-d/%-m"))
      end

      it "retains and renders delivery_date even after the associated schedule is destroyed" do
        order = orders(:history_confirmed_past)
        delivery = order.delivery_date
        schedule = order.schedule

        schedule.destroy!
        expect(order.reload.schedule_id).to be_nil
        expect(order.delivery_date).to eq(delivery)

        get admin_consumer_path(consumers(:one))

        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        dates = month[:orders].to_h { [ it[:id], it[:date] ] }
        expect(dates[order.id]).to eq(I18n.l(delivery, format: "%-d/%-m"))
      end
      it "links each provider of a month to the last receipt the employee sent it" do
        account = accounts(:one_tuviandita_current)
        payment = account.payments.build(provider: account.provider, status: :submitted)
        payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
        payment.save!

        get admin_consumer_path(consumers(:one))

        month = inertia.props[:months].find { it[:key] == Date.current.strftime("%Y-%m") }
        provider = month[:providers].find { it[:id] == account.provider_id }
        expect(provider[:receipt_url]).to eq(receipt_admin_payment_path(payment))
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

      it "returns 404 for a malicious non-numeric consumer id" do
        get admin_consumer_path(id: "malicious")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not signed in as HR" do
      it "redirects visitors without a session to the sign in page" do
        get admin_consumer_path(consumers(:one))

        expect(response).to redirect_to(admin_welcome_path)
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
