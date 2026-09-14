# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BenefitConfigurations", type: :request do
  fixtures :users, :companies, :admins

  let(:admin_user) { users(:one) }
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
  end

  describe "POST /admin/benefit_configurations" do
    it "creates the first configuration and records its author" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 50, monthly_voucher_limit: 20, effective_from: Date.current }
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.benefit_configuration_created"))

      configuration = BenefitConfiguration.last
      expect(configuration.company).to eq(company)
      expect(configuration.created_by).to eq(admin_user)
      expect(configuration.subsidy_percentage).to eq(50)
      expect(configuration.monthly_voucher_limit).to eq(20)
    end

    it "keeps a full history instead of overwriting the previous configuration" do
      previous = BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, monthly_voucher_limit: 20, effective_from: Date.current
      )

      post admin_benefit_configurations_path, params: {
        benefit_configuration: {
          subsidy_percentage: 60, monthly_voucher_limit: 25, effective_from: 1.month.from_now.to_date
        }
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
          benefit_configuration: { subsidy_percentage: -1, monthly_voucher_limit: 20, effective_from: Date.current }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:subsidy_percentage)
    end

    it "rejects an effective_from date in the past" do
      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, monthly_voucher_limit: 20, effective_from: 1.day.ago.to_date }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:effective_from)
    end

    it "rejects a duplicate effective_from for the same company" do
      BenefitConfiguration.create!(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, monthly_voucher_limit: 20, effective_from: Date.current
      )

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, monthly_voucher_limit: 25, effective_from: Date.current }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:effective_from)
    end
  end
end
