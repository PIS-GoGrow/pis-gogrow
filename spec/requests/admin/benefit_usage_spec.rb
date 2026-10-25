# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BenefitUsage", type: :request do
  let(:month) { Date.new(2032, 4, 1) }
  let(:change) { { reference: nil, difference: nil, percent: nil } }
  let(:stats) do
    {
      period: { month: },
      orders: { confirmed_orders: 2, confirmed_meals: 3, pending_orders: 1, pending_meals: 1 },
      benefits: {
        monthly_subsidized_meals: 2, confirmed_meals_without_monthly_subsidy: 1,
        company_subsidy_amount: BigDecimal("1500.25"), monthly_pending_reserved_meals: 1,
        monthly_quota_meals: nil
      },
      employees: { participation_percent: nil, eligibility: { eligible: 0 }, eligible_without_orders: nil },
      trends: { months: [
        { month:, complete: false, confirmed_orders: 2, confirmed_meals: 3,
          monthly_subsidized_meals: 2, company_subsidy_amount: BigDecimal("1500.25"),
          changes: { confirmed_orders: change, confirmed_meals: change,
                     monthly_subsidized_meals: change, company_subsidy_amount: change } }
      ] },
      anomalies: [], warnings: [ { code: "open_month_partial", scope: "trends" } ]
    }
  end
  let(:stats_service) { instance_double(AdminBenefitUsageStats, to_h: stats) }
  let(:summary_service) { instance_double(AdminBenefitUsageSummary, call: { ok: true, text: "Resumen de prueba." }) }

  before do
    allow(Date).to receive(:current).and_return(Date.new(2032, 4, 17))
    Rails.configuration.x.rate_limit_store.clear
    allow(AdminBenefitUsageStats).to receive(:new).and_return(stats_service)
    allow(AdminBenefitUsageSummary).to receive(:new).and_return(summary_service)
  end

  describe "GET /rrhh/uso-beneficio" do
    it "returns only aggregate statistics for an authorized HR user without calling AI" do
      sign_in users(:admin), role: :admin
      stats[:employee] = { name: "Nombre privado", email: "privado@example.com" }
      expect(AdminBenefitUsageSummary).not_to receive(:new)
      expect(AdminBenefitUsageStats).to receive(:new)
        .with(company: companies(:gogrow), month:).and_return(stats_service)

      get admin_benefit_usage_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("period" => { "month" => "2032-04", "closed" => false })
      expect(response.parsed_body.dig("consumption", "company_subsidy_amount")).to eq("1500.25")
      expect(response.parsed_body).to include("trends", "anomalies", "warnings")
      expect(response.body).not_to include("Nombre privado", "privado@example.com")
    end

    it "uses the current month when GET omits month" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).to receive(:new)
        .with(company: companies(:gogrow), month:).and_return(stats_service)

      get admin_benefit_usage_path

      expect(response).to have_http_status(:ok)
    end

    it "keeps unknown indicators as JSON null" do
      sign_in users(:admin), role: :admin
      stats[:benefits][:monthly_subsidized_meals] = nil

      get admin_benefit_usage_path, params: { month: "2032-04" }

      expect(response.parsed_body.dig("consumption", "monthly_subsidized_meals")).to be_nil
    end

    it "rejects an invalid or future month" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).not_to receive(:new)

      [ "2032-13", "2032-4", "2032-05" ].each do |value|
        get admin_benefit_usage_path, params: { month: value }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("error", "code")).to eq("invalid_month")
      end
    end

    it "takes the company from the HR session even if a different company_id is supplied" do
      company = Company.create!(name: "Otra empresa", address: "Rincón 500")
      user = User.create!(name: "Otra persona RRHH", email: "otro-rrhh@example.com", password: "secret-password-123")
      Admin.create!(user:, company:)
      sign_in user, role: :admin
      expect(AdminBenefitUsageStats).to receive(:new).with(company:, month:).and_return(stats_service)

      get admin_benefit_usage_path, params: { month: "2032-04", company_id: companies(:gogrow).id }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /rrhh/uso-beneficio/resumen" do
    it "recalculates server statistics and generates a summary only after an explicit POST" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).to receive(:new)
        .with(company: companies(:gogrow), month:).and_return(stats_service)
      expect(AdminBenefitUsageSummary).to receive(:new)
        .with(payload: an_instance_of(AdminBenefitUsageAiPayload)).and_return(summary_service)
      allow(Time).to receive(:current).and_return(Time.zone.parse("2032-04-17 10:30"))

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "success" => true, "text" => "Resumen de prueba.", "month" => "2032-04",
        "generated_at" => "2032-04-17T10:30:00-03:00", "generated_by_ai" => true
      )
    end

    it "uses the company from the HR session on POST" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).to receive(:new)
        .with(company: companies(:gogrow), month:).and_return(stats_service)

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:ok)
    end

    it "rejects a missing, malformed or future month before generation" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).not_to receive(:new)
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      [ {}, { month: "2032-4" }, { month: "2032-13" }, { month: "2032-05" } ].each do |requested|
        Rails.configuration.x.rate_limit_store.clear
        post admin_benefit_usage_summary_path, params: requested
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("error", "code")).to eq("invalid_month")
      end
    end

    it "rejects arbitrary company, statistics, prompt, model or credential parameters" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).not_to receive(:new)
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      [ :company_id, :stats, :payload, :prompt, :model, :api_key ].each do |field|
        Rails.configuration.x.rate_limit_store.clear
        post admin_benefit_usage_summary_path, params: { month: "2032-04", field => "untrusted" }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body.dig("error", "code")).to eq("invalid_request")
      end
    end

    it "returns a controlled configuration error without exposing secrets" do
      sign_in users(:admin), role: :admin
      allow(summary_service).to receive(:call).and_return(ok: false, error: { code: "configuration_missing" })

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "code")).to eq("configuration_missing")
      expect(response.body).not_to include("ANTHROPIC_API_KEY", "test-only-key", "privado@example.com")
    end

    it "returns a controlled external-service error without affecting GET" do
      sign_in users(:admin), role: :admin
      allow(summary_service).to receive(:call).and_return(ok: false, error: { code: "external_unavailable" })

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "message")).to be_present

      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
    end

    it "limits generation to three requests per HR user within 15 minutes" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageSummary).to receive(:new).exactly(3).times.and_return(summary_service)

      3.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
      end
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body.dig("error", "code")).to eq("rate_limited")
    end
  end

  describe "access control" do
    it "redirects an unauthenticated visitor from both endpoints" do
      expect(AdminBenefitUsageStats).not_to receive(:new)

      get admin_benefit_usage_path
      expect(response).to redirect_to(sign_in_path)

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer from GET and a provider from POST" do
      expect(AdminBenefitUsageStats).not_to receive(:new)
      sign_in users(:one), role: :consumer
      get admin_benefit_usage_path
      expect(response).to redirect_to(root_path)

      sign_in users(:provider_user), role: :provider
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to redirect_to(root_path)
    end
  end
end
