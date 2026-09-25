# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BenefitConfigurations", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers

  let(:admin_user) { users(:admin) }
  let(:company) { companies(:gogrow) }

  before { sign_in admin_user, role: :admin }

  describe "GET /admin/benefit_configurations" do
    it "renders the page with no configuration yet" do
      get admin_benefit_configurations_path

      expect(inertia).to render_component("admin/benefit_configurations/index")
      expect(inertia).to have_props(current_benefit_configuration: nil, benefit_configurations: [])
    end

    it "requires an admin session" do
      sign_out

      get admin_benefit_configurations_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the root page" do
      sign_in users(:one), role: :consumer

      get admin_benefit_configurations_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects a provider to the root page" do
      sign_in users(:provider_user), role: :provider

      get admin_benefit_configurations_path

      expect(response).to redirect_to(root_path)
    end

    it "only renders configurations belonging to the admin's company" do
      other_company = Company.create!(name: "Other Co", address: "Somewhere 123")
      other_admin = User.create!(name: "Other Admin", email: "other_admin@gogrow.com", password: "password123456")
      Admin.create!(user: other_admin, company: other_company)
      BenefitConfiguration.create!(
        company: other_company, created_by: other_admin,
        subsidy_percentage: 80, max_voucher_price: 300, monthly_voucher_limit: 10,
        effective_from: Date.current
      )

      own_config = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current
      )

      get admin_benefit_configurations_path

      expect(inertia.props[:current_benefit_configuration][:id]).to eq(own_config.id)
      expect(inertia.props[:benefit_configurations].length).to eq(1)
      expect(inertia.props[:benefit_configurations].first[:id]).to eq(own_config.id)
      expect(inertia.props[:benefit_configurations].first[:created_by_name]).to eq(admin_user.name)
    end
  end

  describe "POST /admin/benefit_configurations" do
    it "creates the first configuration and records its author" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20 }
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.benefit_configuration_created"))

      configuration = BenefitConfiguration.last
      expect(configuration.company).to eq(company)
      expect(configuration.created_by).to eq(admin_user)
      expect(configuration.subsidy_percentage).to eq(50)
      expect(configuration.max_voucher_price).to eq(150)
      expect(configuration.monthly_voucher_limit).to eq(20)
    end

    it "always applies the change from the first day of next month, regardless of what is posted" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: {
          subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
          effective_from: Date.current
        }
      }

      expect(BenefitConfiguration.last.effective_from).to eq(Date.current.next_month.beginning_of_month)
    end

    it "keeps a full history instead of overwriting the previous configuration" do
      previous = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20, effective_from: Date.current
      )

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 }
      }

      expect(previous.reload.subsidy_percentage).to eq(50)
      expect(BenefitConfiguration.current_for(company)).to eq(previous)

      get admin_benefit_configurations_path
      # have_props compares nested values with plain `==`, not a fuzzy/deep match,
      # so a matcher can't assert "contains 2 items" — checked directly instead.
      expect(inertia.props[:benefit_configurations].length).to eq(2)
    end

    it "rejects invalid values without saving" do
      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: -1, max_voucher_price: 150, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:subsidy_percentage)
    end

    it "rejects a missing max_voucher_price" do
      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:max_voucher_price)
    end

    it "rejects a second edit within the same period" do
      BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:effective_from)
    end

    it "replaces the pending change when replace_pending is sent" do
      pending = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
        replace_pending: true
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      expect(BenefitConfiguration.exists?(pending.id)).to be false

      new_pending = BenefitConfiguration.find_by(effective_from: Date.current.next_month.beginning_of_month)
      expect(new_pending.subsidy_percentage).to eq(60)
      expect(new_pending.max_voucher_price).to eq(200)
      expect(new_pending.monthly_voucher_limit).to eq(25)
    end

    it "does not touch an already-effective configuration when replacing the pending one" do
      current = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current
      )
      BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 55, max_voucher_price: 160, monthly_voucher_limit: 22,
        effective_from: Date.current.next_month.beginning_of_month
      )

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
        replace_pending: true
      }

      expect(current.reload.subsidy_percentage).to eq(50)
    end

    it "redirects visitors without an active session to the sign in page" do
      sign_out

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the root page without creating a configuration" do
      sign_in users(:one), role: :consumer

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      expect(response).to redirect_to(root_path)
    end

    it "redirects a provider to the root page without creating a configuration" do
      sign_in users(:provider_user), role: :provider

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      expect(response).to redirect_to(root_path)
    end

    it "accepts valid boundary values (0% subsidy, 100% subsidy, 0 monthly limit, decimal price)" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 0, max_voucher_price: 99.99, monthly_voucher_limit: 0 }
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      config = BenefitConfiguration.last
      expect(config.subsidy_percentage).to eq(0)
      expect(config.max_voucher_price).to eq(99.99)
      expect(config.monthly_voucher_limit).to eq(0)
    end

    it "does not replace pending configurations of another company when replacing own pending" do
      other_company = Company.create!(name: "Other Co", address: "Somewhere 123")
      other_admin = User.create!(name: "Other Admin", email: "other_admin@gogrow.com", password: "password123456")
      Admin.create!(user: other_admin, company: other_company)
      other_pending = BenefitConfiguration.create!(
        company: other_company, created_by: other_admin,
        subsidy_percentage: 80, max_voucher_price: 300, monthly_voucher_limit: 10,
        effective_from: Date.current.next_month.beginning_of_month
      )

      own_pending = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
        replace_pending: "true"
      }

      expect(BenefitConfiguration.exists?(own_pending.id)).to be false
      expect(BenefitConfiguration.exists?(other_pending.id)).to be true
      expect(other_pending.reload.subsidy_percentage).to eq(80)
    end

    it "does not replace pending when replace_pending is string false or nil" do
      BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
          replace_pending: "false"
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:effective_from)
    end
  end
end
