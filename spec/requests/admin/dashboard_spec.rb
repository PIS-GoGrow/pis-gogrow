# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Dashboard", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments, :benefit_configurations, :benefit_rules

  let(:current_key) { Date.current.strftime("%Y-%m") }
  let(:previous_month) { 1.month.ago.to_date.beginning_of_month }
  let(:previous_key) { previous_month.strftime("%Y-%m") }

  describe "GET /admin/inicio" do
    context "when visitor is unauthenticated" do
      it "redirects to the sign in page" do
        get admin_dashboard_path

        expect(response).to redirect_to(admin_welcome_path)
      end
    end

    context "when signed in with unauthorized roles" do
      it "redirects a consumer to the root page with alert" do
        sign_in users(:one), role: :consumer

        get admin_dashboard_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end

      it "redirects a provider to the root page with alert" do
        sign_in users(:provider_user), role: :provider

        get admin_dashboard_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end
    end

    context "when signed in as admin" do
      before { sign_in users(:admin), role: :admin }

      it "summarizes the current month by default" do
        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("admin/dashboard/index")
        expect(inertia).to have_props(
          today: DateFormat.long(Date.current),
          month: current_key,
          current_month: current_key,
          summary: {
            "meals" => 4, "meals_limit" => 40, "participation" => 100,
            "spending" => 601.0, "paid" => 0.0, "pending" => 601.0, "projected" => 0.0
          }
        )
        expect(inertia.props[:months].pluck("key")).to eq([ current_key, previous_key ])
      end

      # "Ver detalle del consumo" abre este detalle sobre el Inicio.
      it "sends the consumption detail of the selected month" do
        get admin_dashboard_path, params: { month: previous_key }

        expect(inertia.props[:consumption]).to include(
          "month" => I18n.l(previous_month, format: :month_name_year).upcase_first
        )
        expect(inertia.props[:consumption]["providers"].sole).to include("subtotal" => 900.0, "days" => [])
      end

      it "shows the payments of the month before with their status" do
        get admin_dashboard_path

        expect(inertia).to have_props(
          payment_month: I18n.l(previous_month, format: "%B").downcase,
          payments: [ { "name" => "Provider User", "amount" => 900.0, "status" => "approved" } ]
        )
      end

      it "ranks at most three employees with an unsettled month" do
        2.times do |index|
          user = User.create!(name: "Deudor #{index}", email: "deudor#{index}@example.com", password: "secret-password-123")
          consumer = Consumer.create!(user:, company: companies(:gogrow))
          Account.create!(owner: consumer, provider: providers(:tuviandita), month: Date.current, amount: 2_000 + index)
        end

        get admin_dashboard_path

        expect(inertia.props[:debtors].map { it.values_at(:name, :amount, :status) }).to eq([
          [ "Deudor 1", 2001.0, "pending" ],
          [ "Deudor 0", 2000.0, "pending" ],
          [ "Test User", 950.75, "pending" ]
        ])
        expect(inertia.props[:debtors].first[:id]).to eq(Consumer.joins(:user).find_by(users: { name: "Deudor 1" }).id)
      end

      it "summarizes another month without figures from the current one" do
        get admin_dashboard_path, params: { month: previous_key }

        expect(inertia).to have_props(
          month: previous_key,
          summary: {
            "meals" => 0, "meals_limit" => nil, "participation" => 0,
            "spending" => 900.0, "paid" => 900.0, "pending" => 0.0, "projected" => 0.0
          },
          debtors: []
        )
        expect(inertia.props[:payment_month]).to eq(I18n.l(previous_month.prev_month, format: "%B").downcase)
      end

      it "shows everything in zero for a month without data" do
        get admin_dashboard_path, params: { month: "2020-01" }

        expect(inertia).to have_props(
          month: "2020-01",
          summary: {
            "meals" => 0, "meals_limit" => nil, "participation" => 0,
            "spending" => 0.0, "paid" => 0.0, "pending" => 0.0, "projected" => 0.0
          },
          payments: [],
          debtors: []
        )
        expect(inertia.props[:months].last).to eq("key" => "2020-01", "label" => "Enero 2020")
      end

      it "falls back to the current month on an invalid or future month" do
        [ "agosto", "2026-13", "<script>", (Date.current + 2.months).strftime("%Y-%m") ].each do |month|
          get admin_dashboard_path, params: { month: }

          expect(response).to have_http_status(:ok)
          expect(inertia.props[:month]).to eq(current_key)
        end
      end

      it "leaves out the accounts of another company" do
        other = Company.create!(name: "Otra empresa", address: "Rincón 500")
        Account.create!(owner: other, provider: providers(:endulzate), month: previous_month, amount: 300.00)
        Account.create!(owner: other, provider: providers(:tuviandita), month: Date.current, amount: 100.00)

        get admin_dashboard_path

        expect(inertia.props[:summary]["spending"]).to eq(601.0)
        expect(inertia.props[:payments].pluck("name")).to eq([ "Provider User" ])
      end

      it "includes the admin role in the shared auth session props" do
        get admin_dashboard_path

        expect(inertia.props.dig(:auth, :session, :role)).to eq("admin")
      end
    end
  end
end
