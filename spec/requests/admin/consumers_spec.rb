# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Consumers", type: :request do
  fixtures :users, :admins, :consumers, :companies, :orders, :schedules, :menus, :providers,
    :benefits, :accounts, :payments

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
      before { sign_in users(:admin_user) }

      it "renders the consumers page" do
        get admin_consumers_path
        expect(inertia).to render_component("admin/consumers/index")
      end

      it "lists every employee when there is no query" do
        get admin_consumers_path
        expect(inertia.props[:consumers].pluck(:id)).to contain_exactly(consumers(:one).id, consumers(:other).id)
      end

      it "filters employees by name, email or company" do
        get admin_consumers_path, params: { query: "Test User" }
        expect(inertia.props[:consumers].pluck(:id)).to contain_exactly(consumers(:one).id)

        get admin_consumers_path, params: { query: "other-consumer@example.com" }
        expect(inertia.props[:consumers].pluck(:id)).to contain_exactly(consumers(:other).id)
      end
    end
  end

  describe "GET /admin/consumers/:id" do
    context "when signed in as HR" do
      before { sign_in users(:admin_user) }

      it "renders the consumer's centralized detail" do
        get admin_consumer_path(consumers(:one))

        expect(inertia).to render_component("admin/consumers/show")
        expect(inertia.props[:consumer]).to include(name: "Test User", email: "one@example.com", company_name: "GoGrow")
        expect(inertia.props[:benefits].pluck(:id)).to contain_exactly(benefits(:one).id)
        expect(inertia.props[:debts].pluck(:id)).to contain_exactly(accounts(:unpaid).id, accounts(:failed_payment).id)
        expect(inertia.props[:payments].pluck(:id)).to contain_exactly(payments(:paid).id, payments(:failed).id)
      end
    end
  end
end
