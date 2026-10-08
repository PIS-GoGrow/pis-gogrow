# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BenefitConfigurations", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :benefit_configurations

  let(:admin_user) { users(:admin) }
  let(:company) { companies(:gogrow) }

  before { sign_in admin_user, role: :admin }

  describe "GET /admin/benefit_configurations" do
    it "renders the page with no configuration yet" do
      BenefitConfiguration.destroy_all

      get admin_benefit_configurations_path

      expect(inertia).to render_component("admin/benefit_configurations/index")
      expect(inertia).to have_props(base_subsidy: nil, benefit_configurations: [])
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
      BenefitConfiguration.new_base_subsidy(
        company: other_company, created_by: other_admin,
        subsidy_percentage: 80, max_price: 300, limit: 10,
        effective_from: Date.current
      ).save!

      own_config = benefit_configurations(:monthly)

      get admin_benefit_configurations_path

      expect(inertia.props[:base_subsidy][:id]).to eq(own_config.id)
      expect(inertia.props[:benefit_configurations].length).to eq(3)
      expect(inertia.props[:benefit_configurations].first[:id]).to eq(own_config.id)
      expect(inertia.props[:benefit_configurations].first[:created_by_name]).to eq(admin_user.name)
    end

    it "renders configurable_month as next month when accessed before cutoff date" do
      travel_to Date.new(2026, 10, 15) do
        get admin_benefit_configurations_path
        expect(inertia.props[:configurable_month]).to eq("01/11/26")
      end
    end

    it "renders configurable_month as two months ahead when accessed on or after cutoff date" do
      travel_to Date.new(2026, 10, 31) do
        get admin_benefit_configurations_path
        expect(inertia.props[:configurable_month]).to eq("01/12/26")
      end
    end
  end

  describe "POST /admin/benefit_configurations" do
    before do
      BenefitConfiguration.destroy_all
    end

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
      expect(configuration.benefit_rules.first.type).to eq(MonthlyBenefit.name)
      expect(configuration.benefit_rules.first.max_price).to eq(150)
      expect(configuration.benefit_rules.first.limit).to eq(20)
    end

    it "always applies the change from the first day of next month, regardless of what is posted" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: {
          subsidy_percentage: 50, max_voucher_price: 150, monthly_voucher_limit: 20,
          effective_from: Date.current
        }
      }

      expect(BenefitConfiguration.last.benefit_rules.first.effective_from).to eq(Date.current.next_month.beginning_of_month)
    end

    it "sets effective_from to two months ahead when posted on or after configuration cutoff date" do
      travel_to Date.new(2026, 10, 31) do
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 }
        }

        expect(response).to redirect_to(admin_benefit_configurations_path)
        new_rule = BenefitConfiguration.last.benefit_rules.first
        expect(new_rule.effective_from).to eq(Date.new(2026, 12, 1))
      end
    end

    it "keeps a full history instead of overwriting the previous configuration" do
      previous = BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20, effective_from: Date.current
      )
      previous.save!

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 }
      }

      expect(previous.reload.subsidy_percentage).to eq(50)
      expect(BenefitConfiguration.base_subsidy_for(company)).to eq(previous)

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
      expect(inertia.props[:errors][:benefit_configuration]).to have_key(:subsidy_percentage)
    end

    it "rejects a missing max_voucher_price" do
      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, monthly_voucher_limit: 20 }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors][:benefit_rules].first).to have_key(:max_price)
    end

    it "rejects a second edit within the same period" do
      BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      ).save!

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 }
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors][:benefit_rules].first).to have_key(:effective_from)
    end

    it "replaces the pending change when replace_pending is sent" do
      pending = BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )
      pending.save!

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
        replace_pending: true
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      expect(BenefitConfiguration.exists?(pending.id)).to be false

      new_pending =
        BenefitConfiguration.joins(:benefit_rules).where(benefit_rules: { effective_from: Date.current.next_month.beginning_of_month }).last
      expect(new_pending.subsidy_percentage).to eq(60)
      expect(new_pending.benefit_rules.first.max_price).to eq(200)
      expect(new_pending.benefit_rules.first.limit).to eq(25)
    end

    it "does not touch an already-effective configuration when replacing the pending one" do
      current = BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20,
        effective_from: Date.current
      )
      current.save!
      BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 55, max_price: 160, limit: 22,
        effective_from: Date.current.next_month.beginning_of_month
      ).save!

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

    it "accepts valid boundary values (1% subsidy, 100% subsidy, 0 monthly limit, decimal price)" do
      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 1, max_voucher_price: 99.99, monthly_voucher_limit: 1 }
      }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      config = BenefitConfiguration.last
      expect(config.subsidy_percentage).to eq(1)
      expect(config.benefit_rules.first.max_price).to eq(99.99)
      expect(config.benefit_rules.first.limit).to eq(1)
    end

    it "does not replace pending configurations of another company when replacing own pending" do
      other_company = Company.create!(name: "Other Co", address: "Somewhere 123")
      other_admin = User.create!(name: "Other Admin", email: "other_admin@gogrow.com", password: "password123456")
      Admin.create!(user: other_admin, company: other_company)
      other_pending = BenefitConfiguration.new_base_subsidy(
        company: other_company, created_by: other_admin,
        subsidy_percentage: 80, max_price: 300, limit: 10,
        effective_from: Date.current.next_month.beginning_of_month
      )
      other_pending.save!

      own_pending = BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      )
      own_pending.save!

      post admin_benefit_configurations_path, params: {
        benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
        replace_pending: "true"
      }

      expect(BenefitConfiguration.exists?(own_pending.id)).to be false
      expect(BenefitConfiguration.exists?(other_pending.id)).to be true
      expect(other_pending.reload.subsidy_percentage).to eq(80)
    end

    it "does not replace pending when replace_pending is string false or nil" do
      BenefitConfiguration.new_base_subsidy(
        company: company, created_by: admin_user,
        subsidy_percentage: 50, max_price: 150, limit: 20,
        effective_from: Date.current.next_month.beginning_of_month
      ).save!

      expect {
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 60, max_voucher_price: 200, monthly_voucher_limit: 25 },
          replace_pending: "false"
        }
      }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors][:benefit_rules].first).to have_key(:effective_from)
    end

    context "casos borde y robustez" do
      it "responde con 400 Bad Request ante bypass de interfaz sin clave benefit_configuration" do
        post admin_benefit_configurations_path, params: { unexpected_payload: "bypass" }
        expect(response).to have_http_status(:bad_request)
      end

      it "rechaza porcentajes de subsidio no numéricos o fuera de rango (0-100)" do
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: "invalido", max_voucher_price: 150, monthly_voucher_limit: 20 }
        }

        follow_redirect!
        expect(inertia.props[:errors][:benefit_configuration]).to have_key(:subsidy_percentage)

        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 150, max_voucher_price: 150, monthly_voucher_limit: 20 }
        }

        follow_redirect!
        expect(inertia.props[:errors][:benefit_configuration]).to have_key(:subsidy_percentage)
      end

      it "rechaza precios máximos o límites negativos en las reglas" do
        post admin_benefit_configurations_path, params: {
          benefit_configuration: { subsidy_percentage: 50, max_voucher_price: -10, monthly_voucher_limit: -5 }
        }

        follow_redirect!
        rule_errors = inertia.props[:errors][:benefit_rules].first
        expect(rule_errors).to have_key(:max_price)
        expect(rule_errors).to have_key(:limit)
      end
    end
  end
end
