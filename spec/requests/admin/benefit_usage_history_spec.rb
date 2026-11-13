# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BenefitUsage history", type: :request do
  around { |example| travel_to(Time.zone.local(2026, 11, 4, 12)) { example.run } }

  before { sign_in users(:admin), role: :admin }

  it "serves September and October snapshots without exposing individual or fictional data elsewhere" do
    company = companies(:gogrow)
    ibp_041_2026_snapshots(company:)

    get admin_benefit_usage_path, params: { month: "2026-09" }
    september = response.parsed_body
    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Benefit-Usage-Source"]).to eq("historical_snapshot")
    expect(response.headers["X-Benefit-Usage-State"]).to eq("closed")
    expect(september.dig("history", "metrics")).to include("employees" => 38, "eligible_employees" => 36,
                                                         "confirmed_meals" => 28)

    get admin_benefit_usage_path, params: { month: "2026-10" }
    october = response.parsed_body
    expect(october.dig("history", "metrics")).to include("employees" => 40, "eligible_employees" => 38,
                                                       "confirmed_meals" => 44, "monthly_subsidized_meals" => 40)
    expect(october.dig("history", "comparisons").last).to include("quality" => "verified_close")
    expect(october.dig("history", "comparisons").last.dig("changes", "participation_percent", "difference_points"))
      .to eq("8.77")
    expect(october.dig("history", "metrics", "company_subsidy_amount")).to match(/\A6600(?:\.0+)?\z/)
    expect(october.dig("consumption", "confirmed_meals")).to eq(44)
    expect(october.dig("capacity", "monthly_available_meals")).to eq(716)
    expect(october.dig("history", "metrics", "monthly_available_meals")).to eq(716)
    expect(october.dig("history", "metrics", "monthly_unused_closed_meals")).to eq(716)
    expect(response.body).not_to match(/"(?:consumer_id|user_id|email|name|address)"\s*:/)
  end

  it "exposes a verified fictional close as such, without changing the current-month contract" do
    company = companies(:gogrow)
    ibp_041_verified_close(company:)

    get admin_benefit_usage_path, params: { month: "2026-08" }
    expect(response.parsed_body.dig("history", "period")).to include("state" => "closed", "fictional" => true)
    expect(response.parsed_body.dig("capacity", "monthly_quota_meals")).to eq(660)

    get admin_benefit_usage_path, params: { month: "2026-11" }
    expect(response.headers["X-Benefit-Usage-Source"]).to eq("current_calculation")
    expect(response.headers["X-Benefit-Usage-State"]).to eq("provisional")
    expect(response.parsed_body).not_to have_key("history")
  end

  it "reports missing history without inserting a snapshot and rejects months outside the window" do
    company = companies(:gogrow)

    get admin_benefit_usage_path, params: { month: "2026-07" }
    expect(response.parsed_body.dig("history", "period", "state")).to eq("missing_snapshot")
    expect(response.parsed_body.dig("history", "metrics", "eligible_employees")).to be_nil
    expect(BenefitUsageMonthlySnapshot.find_by(company:, month: Date.new(2026, 7, 1))).to be_nil

    get admin_benefit_usage_path, params: { month: "2025-11" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  describe "POST /rrhh/uso-beneficio/resumen" do
    let(:client) { instance_double(AnthropicMessagesClient) }
    let(:sent_payloads) { [] }

    before do
      Rails.configuration.x.rate_limit_store.clear
      allow(AnthropicMessagesClient).to receive(:new).and_return(client)
      allow(client).to receive(:create_summary) do |**arguments|
        sent_payloads << JSON.parse(arguments.fetch(:payload_json))
        { ok: true, text: "Resumen simulado de RRHH." }
      end
    end

    def post_summary(month:, **extra)
      get admin_benefit_usage_path, params: { month: }
      revision = response.parsed_body["analysis_revision"]
      post admin_benefit_usage_summary_path, params: { month:, analysis_revision: revision }.merge(extra)
    end

    it "uses the September and October snapshots only after explicit POSTs" do
      ibp_041_2026_snapshots(company: companies(:gogrow))
      expect(client).not_to have_received(:create_summary)

      %w[2026-09 2026-10].each do |month|
        post_summary(month:)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("month" => month, "text" => "Resumen simulado de RRHH.")
      end

      expect(sent_payloads.pluck("period").pluck("state")).to eq(%w[closed closed])
      expect(sent_payloads[0].fetch("metrics")).to include("employees" => 38, "eligible_employees" => 36,
                                                         "eligible_with_confirmed_orders" => 12,
                                                         "monthly_quota_meals" => 720, "confirmed_meals" => 28)
      expect(sent_payloads[1].fetch("metrics")).to include("employees" => 40, "eligible_employees" => 38,
                                                         "eligible_with_confirmed_orders" => 16,
                                                         "monthly_quota_meals" => 760, "confirmed_meals" => 44)
      expect(sent_payloads[1].dig("comparison", "changes", "participation_percent", "difference_points"))
        .to eq(8.77)
      expect(sent_payloads[1].dig("period", "captured_at")).to eq(Time.zone.local(2026, 10, 31, 23, 55).iso8601)
      expect(JSON.generate(sent_payloads)).not_to match(/"(?:consumer_id|user_id|email|name|address|bank_account)"\s*:/)
    end

    it "uses verified closed data, including the unused quota" do
      ibp_041_verified_close(company: companies(:gogrow))

      post_summary(month: "2026-08")

      expect(response).to have_http_status(:ok)
      expect(sent_payloads.sole.dig("period", "state")).to eq("closed")
      expect(sent_payloads.sole.dig("metrics", "monthly_unused_closed_meals")).to eq(640)
    end

    it "rejects a changed historical snapshot without calling Claude" do
      _, snapshot = ibp_041_2026_snapshots(company: companies(:gogrow))
      get admin_benefit_usage_path, params: { month: "2026-10" }
      revision = response.parsed_body.fetch("analysis_revision")
      snapshot.correction_authorized = true
      snapshot.update!(company_subsidy_amount: 6700)

      post admin_benefit_usage_summary_path, params: { month: "2026-10", analysis_revision: revision }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("stale_analysis")
      expect(client).not_to have_received(:create_summary)
    end

    it "rejects a changed historical source without calling Claude" do
      get admin_benefit_usage_path, params: { month: "2026-10" }
      revision = response.parsed_body.fetch("analysis_revision")
      ibp_041_2026_snapshots(company: companies(:gogrow))

      post admin_benefit_usage_summary_path, params: { month: "2026-10", analysis_revision: revision }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("stale_analysis")
      expect(client).not_to have_received(:create_summary)
    end

    it "rejects an October current-month revision when November begins" do
      allow(Date).to receive(:current).and_return(Date.new(2026, 10, 31))
      get admin_benefit_usage_path, params: { month: "2026-10" }
      revision = response.parsed_body.fetch("analysis_revision")
      expect(response.headers["X-Benefit-Usage-Source"]).to eq("current_calculation")
      allow(Date).to receive(:current).and_return(Date.new(2026, 11, 1))

      post admin_benefit_usage_summary_path, params: { month: "2026-10", analysis_revision: revision }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("stale_analysis")
      expect(client).not_to have_received(:create_summary)
    end

    it "refuses to call Claude when reconstruction has no verifiable activity" do
      post_summary(month: "2026-07")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("insufficient_data")
      expect(client).not_to have_received(:create_summary)
    end

    it "does not trust browser statistics or another company id" do
      ibp_041_2026_snapshots(company: companies(:gogrow))
      post_summary(month: "2026-10", stats: { confirmed_meals: 999 }, company_id: -1)

      expect(response).to have_http_status(:bad_request)
      expect(client).not_to have_received(:create_summary)
    end

    it "does not read another company's historical snapshot" do
      ibp_041_2026_snapshots(company: companies(:gogrow))
      other = Company.create!(name: "Empresa aislada")
      user = User.create!(name: "RRHH aislado", email: "rrhh-aislado@example.test",
                          password: "secret-password-123")
      Admin.create!(user:, company: other)
      sign_in user, role: :admin

      post_summary(month: "2026-10")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("insufficient_data")
      expect(client).not_to have_received(:create_summary)
    end

    it "rejects a summary month outside the twelve-month window" do
      post admin_benefit_usage_summary_path, params: { month: "2025-11" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_month")
      expect(client).not_to have_received(:create_summary)
    end

    it "retains rate limiting and reports a simulated Claude failure" do
      ibp_041_2026_snapshots(company: companies(:gogrow))
      allow(client).to receive(:create_summary).and_return(ok: false, error: { code: "external_unavailable" })
      post_summary(month: "2026-10")
      expect(response).to have_http_status(:service_unavailable)

      2.times do
        post_summary(month: "2026-10")
        expect(response).to have_http_status(:service_unavailable)
      end
      post_summary(month: "2026-10")
      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body.dig("error", "code")).to eq("rate_limited")
    end
  end
end
