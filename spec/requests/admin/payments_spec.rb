# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Payments", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments

  # La cuenta de otra empresa se crea acá y no en los fixtures: las cuentas se
  # cuentan en los specs de cobros y una fila más les cambiaría los totales.
  let(:other_company_account) do
    company = Company.create!(name: "Otra empresa", address: "Rincón 500")

    Account.create!(owner: company, provider: providers(:tuviandita), month: Date.current, amount: 100.00)
  end

  describe "GET /admin/payments" do
    it "redirects to sign in without a session" do
      get admin_payments_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get admin_payments_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "lists only what the company still owes, and not what its employees owe" do
        other_company_account

        get admin_payments_path

        expect(inertia).to render_component("admin/payments/index")
        expect(inertia.props[:accounts].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_current).id)
        expect(inertia.props[:total_debt]).to eq(601.0)
      end

      it "moves a period with an approved receipt to the history" do
        get admin_payments_path

        expect(inertia.props[:history].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_previous).id)
      end

      it "counts the subsidy and the meals of the current month" do
        get admin_payments_path

        expect(inertia.props[:current_month]).to eq("amount" => 601.0, "meals" => 4, "limit" => nil)
      end

      it "lists every provider so the ones without debt also show up" do
        get admin_payments_path

        expect(inertia.props[:providers].pluck(:name))
          .to eq([ "Office Provider User", "Other Provider User", "Provider User" ])
      end
    end
  end

  describe "GET /admin/payments/:id" do
    it "redirects to sign in without a session" do
      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      expect(response).to redirect_to(sign_in_path)
    end

    it "answers with the confirmed orders that make up the period" do
      sign_in users(:admin), role: :admin

      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      body = response.parsed_body

      expect(body["month"]).to eq(I18n.l(Date.current, format: :month_year))
      expect(body["amount"]).to eq(601.0)
      expect(body["orders"].pluck("id")).to contain_exactly(
        orders(:upcoming_confirmed_future).id,
        orders(:history_confirmed_past).id,
        orders(:other_consumer_upcoming).id
      )
    end

    it "responds with not found for an account of another company" do
      sign_in users(:admin), role: :admin

      get admin_payment_path(other_company_account)

      expect(response).to have_http_status(:not_found)
    end
  end
end
