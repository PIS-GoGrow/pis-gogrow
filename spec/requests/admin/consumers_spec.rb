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

  describe "GET /admin/consumers" do
    it "redirects visitors to the sign in page" do
      get admin_consumers_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects users without an admin profile" do
      sign_in users(:one)
      get admin_consumers_path
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
    end
  end

  describe "GET /admin/consumers/:id" do
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
    end
  end
end
