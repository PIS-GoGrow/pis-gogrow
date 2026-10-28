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
        monthly_quota_meals: nil, monthly_available_meals: nil
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
      expect(response.parsed_body.fetch("capacity")).to eq(
        "monthly_quota_meals" => nil, "monthly_pending_reserved_meals" => 1,
        "monthly_available_meals" => nil
      )
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

    it "redirects a provider from GET and a consumer from POST without calculating or generating" do
      expect(AdminBenefitUsageStats).not_to receive(:new)
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      sign_in users(:provider_user), role: :provider
      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to redirect_to(root_path)
      expect(response.body).not_to include("consumption", "privado@example.com")

      sign_in users(:one), role: :consumer
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to redirect_to(root_path)
      expect(response.body).not_to include("Resumen", "privado@example.com")
    end
  end

  describe "rate limit boundaries" do
    let(:second_admin) do
      user = User.create!(name: "Segundo administrador", email: "segundo-admin@example.test",
                          password: "secret-password-123")
      Admin.create!(user:, company: companies(:gogrow))
      user
    end

    it "keeps separate counters for administrators and ignores a supplied user_id" do
      expect(AdminBenefitUsageSummary).to receive(:new).exactly(6).times.and_return(summary_service)
      sign_in users(:admin), role: :admin
      3.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
      end

      sign_in second_admin, role: :admin
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)

      sign_in users(:admin), role: :admin
      post admin_benefit_usage_summary_path, params: { month: "2032-04", user_id: second_admin.id }
      expect(response).to have_http_status(:too_many_requests)

      sign_in second_admin, role: :admin
      2.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
      end
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "allows a new request after the first counter entry expires" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageSummary).to receive(:new).exactly(4).times.and_return(summary_service)

      travel_to Time.zone.local(2032, 4, 17, 12) do
        3.times do
          post admin_benefit_usage_summary_path, params: { month: "2032-04" }
          expect(response).to have_http_status(:ok)
        end
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:too_many_requests)

        travel 15.minutes + 1.second
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
      end
    end

    it "counts invalid POSTs but keeps GET outside the generation limit" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      [ {}, { month: "2032-13" }, { month: "2032-04", company_id: companies(:gogrow).id } ].each do |parameters|
        post admin_benefit_usage_summary_path, params: parameters
        expect(response).to have_http_status(parameters.key?(:company_id) ? :bad_request : :unprocessable_content)
      end
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:too_many_requests)

      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
    end

    it "does not let unauthorized POSTs consume an administrator's counter" do
      expect(AdminBenefitUsageStats).to receive(:new).exactly(3).times.and_return(stats_service)
      expect(AdminBenefitUsageSummary).to receive(:new).exactly(3).times.and_return(summary_service)

      4.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to redirect_to(sign_in_path)
      end

      sign_in users(:one), role: :consumer
      4.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to redirect_to(root_path)
      end

      sign_in users(:admin), role: :admin
      3.times do
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
      end
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "CSRF protection" do
    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    it "rejects a POST without a token before calculating or generating" do
      sign_in users(:admin), role: :admin
      expect(AdminBenefitUsageStats).not_to receive(:new)
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "accepts a valid Rails authenticity token and restores the test setting afterwards" do
      get root_path
      token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')&.[]("content")
      expect(token).to be_present
      sign_in users(:admin), role: :admin

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }, headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("generated_by_ai")).to be(true)
    end
  end

  describe "integration with real statistics and a simulated Anthropic transport" do
    let(:other_company) { Company.create!(name: "Empresa centinela B", address: "PRIVATE-B-COMPANY-ADDRESS") }
    let(:other_admin) do
      User.create!(name: "PRIVATE-B-ADMIN-NAME", email: "private-b-admin@example.test", password: "secret-password-123")
    end
    let(:other_consumer) do
      user = User.create!(name: "PRIVATE-B-CONSUMER-NAME", email: "private-b-consumer@example.test",
                          password: "secret-password-123")
      Consumer.create!(user:, company: other_company, address: "PRIVATE-B-CONSUMER-ADDRESS")
    end
    let(:requests) { [] }
    let(:transport) do
      Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") do |request|
            requests << { url: request.url.to_s, headers: request.request_headers.to_h, body: request.body.dup }
            body = JSON.generate(type: "message", role: "assistant", stop_reason: "end_turn",
                                 content: [ { type: "text", text: "Resumen simulado." } ])
            [ 200, { "Content-Type" => "application/json" }, body ]
          end
        end
      end
    end

    def insert_usage_order(consumer:, date:, meals:, subsidy:, benefit:)
      amount = 300 * meals
      inserted = Order.insert!({
        consumer_id: consumer.id, delivery_date: date, status: Order.statuses.fetch("confirmed"),
        amount: meals, price: amount, discounted_price: amount - subsidy,
        delivery_method: Order.delivery_methods.fetch("office"), selected_options: [],
        address: "PRIVATE-ORDER-ADDRESS", notes: "PRIVATE-ORDER-NOTES",
        created_at: Time.current, updated_at: Time.current
      })
      order = Order.find(inserted.rows.first.first)
      OrderBenefit.create!(order:, benefit:, benefit_used: meals)
    end

    def grant_monthly(consumer:, configuration:, date:)
      Benefit.create!(consumer:, benefit_configuration: configuration, amount: 20, percentage: 50,
                      due_date: date.end_of_month, status: date < month ? :expired : :future)
    end

    before do
      allow(AdminBenefitUsageStats).to receive(:new).and_call_original
      allow(AdminBenefitUsageSummary).to receive(:new).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test-only-key")
      allow(ENV).to receive(:[]).with("ANTHROPIC_MODEL").and_return("configured-test-model")
      simulated_transport = transport
      allow(Faraday).to receive(:new).and_raise("unexpected external connection")
      allow(Faraday).to receive(:new).with(url: "https://api.anthropic.com").and_return(simulated_transport)

      users(:one).update_columns(name: "PRIVATE-A-CONSUMER-NAME", email: "private-a-consumer@example.test")
      consumers(:one).update_columns(address: "PRIVATE-A-CONSUMER-ADDRESS")
      Admin.create!(user: other_admin, company: other_company)
      configuration = BenefitConfiguration.create!(company: other_company, created_by: other_admin,
                                                   name: "Subsidio mensual B", subsidy_percentage: 50)
      MonthlyBenefit.insert!({ benefit_configuration_id: configuration.id, effective_from: month.prev_month,
                               limit: 20, max_price: 500, created_at: Time.current, updated_at: Time.current })

      [ [ consumers(:one), benefit_configurations(:monthly), 4, 2, 400, 120 ],
        [ other_consumer, configuration, 9, 5, 900, 750 ] ].each do |consumer, config, prior_meals, current_meals, prior_subsidy, current_subsidy|
        previous_grant = grant_monthly(consumer:, configuration: config, date: month.prev_month)
        current_grant = grant_monthly(consumer:, configuration: config, date: month)
        insert_usage_order(consumer:, date: month.prev_month, meals: prior_meals, subsidy: prior_subsidy,
                           benefit: previous_grant)
        insert_usage_order(consumer:, date: month, meals: current_meals, subsidy: current_subsidy,
                           benefit: current_grant)
      end
    end

    it "isolates real GET statistics, benefits, and trends even with another company_id" do
      expect(AdminBenefitUsageSummary).not_to receive(:new)

      [ [ users(:admin), other_company.id, 2, "120.00", 4, "400.00" ],
        [ other_admin, companies(:gogrow).id, 5, "750.00", 9, "900.00" ] ].each do |admin, foreign_id, meals, subsidy, prior_meals, prior_subsidy|
        sign_in admin, role: :admin
        get admin_benefit_usage_path, params: { month: "2032-04", company_id: foreign_id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("consumption", "confirmed_meals")).to eq(meals)
        expect(response.parsed_body.dig("consumption", "monthly_subsidized_meals")).to eq(meals)
        expect(response.parsed_body.dig("consumption", "company_subsidy_amount")).to eq(subsidy)
        expect(response.parsed_body.dig("trends", 2)).to include("confirmed_meals" => prior_meals,
                                                                "company_subsidy_amount" => prior_subsidy)
        expect(response.body).not_to include("PRIVATE-", "@example.test", "PRIVATE-ORDER-NOTES")
        expect(response.body).not_to match(/"(?:company_id|consumer_id|user_id|order_id|benefit_id|address|email|name)"\s*:/)
        expect(response.parsed_body.keys).to contain_exactly("schema_version", "period", "consumption",
                                                              "capacity", "participation", "trends", "anomalies", "warnings")
      end
      expect(requests).to be_empty
    end

    it "runs both companies through statistics, payload, summary, and the simulated Messages API" do
      [ [ users(:admin), 2, "120.00", 4 ], [ other_admin, 5, "750.00", 9 ] ].each do |admin, meals, subsidy, prior_meals|
        sign_in admin, role: :admin
        post admin_benefit_usage_summary_path, params: { month: "2032-04" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true, "text" => "Resumen simulado.",
                                                "month" => "2032-04", "generated_by_ai" => true)
        expect(Time.iso8601(response.parsed_body.fetch("generated_at"))).to be_a(Time)
        outbound = requests.last
        expect(outbound[:url]).to eq("https://api.anthropic.com/v1/messages")
        expect(outbound[:headers]).to include("Authorization" => "Bearer test-only-key",
                                              "anthropic-version" => "2026-10-21")
        body = JSON.parse(outbound[:body])
        expect(body).to include("model" => "configured-test-model", "max_tokens" => 500)
        payload = JSON.parse(body.fetch("messages").sole.fetch("content"))
        expect(payload).not_to have_key("capacity")
        expect(payload.dig("consumption", "confirmed_meals")).to eq(meals)
        expect(payload.dig("consumption", "monthly_subsidized_meals")).to eq(meals)
        expect(payload.dig("consumption", "company_subsidy_amount")).to eq(subsidy)
        expect(payload.dig("trends", 2, "confirmed_meals")).to eq(prior_meals)
        expect(outbound[:body]).not_to include("PRIVATE-", "@example.test", "PRIVATE-ORDER-NOTES")
        expect(outbound[:body]).not_to match(/"(?:company_id|consumer_id|user_id|order_id|benefit_id|address|email|name)"\s*:/)
        expect(payload.keys).to contain_exactly("schema_version", "period", "consumption", "participation",
                                                "trends", "anomalies", "warnings")
      end
      expect(requests.size).to eq(2)
    end

    it "serves a one-employee company through GET and POST without exposing individual records" do
      expect(other_company.consumers.count).to eq(1)
      sign_in other_admin, role: :admin

      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("consumption", "confirmed_meals")).to eq(5)
      expect(response.parsed_body.fetch("capacity")).to eq(
        "monthly_quota_meals" => 20, "monthly_pending_reserved_meals" => 0,
        "monthly_available_meals" => 15
      )
      expect(response.body).not_to include("PRIVATE-", "@example.test", "consumer_id", "user_id")

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
      expect(requests.size).to eq(1)
      outbound = JSON.parse(requests.sole.fetch(:body))
      ai_payload = JSON.parse(outbound.fetch("messages").sole.fetch("content"))
      expect(ai_payload).not_to have_key("capacity")
      expect(requests.sole.fetch(:body)).not_to include("PRIVATE-", "@example.test", "consumer_id", "user_id")
    end

    it "rejects foreign company parameters and keeps private values out of errors" do
      sign_in users(:admin), role: :admin

      post admin_benefit_usage_summary_path, params: { month: "2032-04", company_id: other_company.id }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_request")
      expect(response.body).not_to include("PRIVATE-", "@example.test", "test-only-key")
      expect(requests).to be_empty
    end
  end

  describe "Anthropic failure handling through the RRHH endpoints" do
    let(:attempts) { [] }
    let(:provider_status) { 200 }
    let(:provider_body) { "{}" }
    let(:provider_error) { nil }
    let(:transport) do
      Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") do |request|
            attempts << request
            raise provider_error if provider_error

            [ provider_status, { "Content-Type" => "application/json" }, provider_body ]
          end
        end
      end
    end

    before do
      allow(AdminBenefitUsageSummary).to receive(:new).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test-only-key")
      allow(ENV).to receive(:[]).with("ANTHROPIC_MODEL").and_return("configured-test-model")
      simulated_transport = transport
      allow(Faraday).to receive(:new).and_raise("unexpected external connection")
      allow(Faraday).to receive(:new).with(url: "https://api.anthropic.com").and_return(simulated_transport)
      sign_in users(:admin), role: :admin
    end

    [
      [ "API key", "", "configured-test-model" ],
      [ "model", "test-only-key", "" ],
      [ "both values", nil, nil ]
    ].each do |label, key, model|
      it "returns 503 without an external call when #{label} is missing and leaves GET available" do
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(key)
        allow(ENV).to receive(:[]).with("ANTHROPIC_MODEL").and_return(model)

        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body.dig("error", "code")).to eq("configuration_missing")
        expect(response.body).not_to include("test-only-key", "ANTHROPIC_API_KEY")
        expect(attempts).to be_empty

        get admin_benefit_usage_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("consumption", "confirmed_meals")).to eq(3)
      end
    end

    {
      401 => [ "authentication_failed", :bad_gateway ],
      402 => [ "permission_or_billing", :service_unavailable ],
      403 => [ "permission_or_billing", :service_unavailable ],
      429 => [ "rate_limited", :too_many_requests ],
      500 => [ "external_unavailable", :service_unavailable ],
      502 => [ "external_unavailable", :service_unavailable ],
      503 => [ "external_unavailable", :service_unavailable ]
    }.each do |status, (code, public_status)|
      it "maps provider HTTP #{status} to a controlled #{code} response" do
        allow(self).to receive(:provider_status).and_return(status)
        allow(self).to receive(:provider_body).and_return(
          JSON.generate(type: "error", error: { type: "provider_error", message: "PRIVATE-PROVIDER-DIAGNOSTIC" })
        )

        post admin_benefit_usage_summary_path, params: { month: "2032-04" }

        expect(response).to have_http_status(public_status)
        expect(response.parsed_body.dig("error", "code")).to eq(code)
        expect(response.body).not_to include("PRIVATE-PROVIDER-DIAGNOSTIC", "test-only-key")
        expect(attempts.size).to eq(1)
      end
    end

    it "maps a documented workspace spending limit without exposing its provider message" do
      allow(self).to receive(:provider_status).and_return(400)
      allow(self).to receive(:provider_body).and_return(
        JSON.generate(type: "error", error: { type: "invalid_request_error",
                                             message: "You have reached your specified workspace API usage limits" })
      )

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "code")).to eq("spend_limit_reached")
      expect(response.body).not_to include("You have reached")
      expect(attempts.size).to eq(1)
    end

    [
      [ "refusal", "refused" ],
      [ "max_tokens", "invalid_response" ]
    ].each do |stop_reason, code|
      it "does not publish an HTTP 200 #{stop_reason} response as a complete summary" do
        allow(self).to receive(:provider_body).and_return(
          JSON.generate(type: "message", role: "assistant", stop_reason:,
                        content: [ { type: "text", text: "PRIVATE-INCOMPLETE-SUMMARY" } ])
        )

        post admin_benefit_usage_summary_path, params: { month: "2032-04" }

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body.dig("error", "code")).to eq(code)
        expect(response.body).not_to include("PRIVATE-INCOMPLETE-SUMMARY")
        expect(attempts.size).to eq(1)
      end
    end

    [
      [ Faraday::TimeoutError, "timeout", :gateway_timeout ],
      [ Faraday::ConnectionFailed, "external_unavailable", :service_unavailable ]
    ].each do |error_class, code, public_status|
      it "handles #{error_class} with one attempt and keeps statistics available" do
        allow(self).to receive(:provider_error).and_return(error_class.new("PRIVATE-NETWORK-DIAGNOSTIC"))
        original_orders = Order.count

        post admin_benefit_usage_summary_path, params: { month: "2032-04" }
        expect(response).to have_http_status(public_status)
        expect(response.parsed_body.dig("error", "code")).to eq(code)
        expect(response.body).not_to include("PRIVATE-NETWORK-DIAGNOSTIC", "test-only-key")
        expect(attempts.size).to eq(1)

        get admin_benefit_usage_path, params: { month: "2032-04" }
        expect(response).to have_http_status(:ok)
        expect(Order.count).to eq(original_orders)
      end
    end

    it "keeps real statistics unchanged across a failed generation and a second GET" do
      allow(AdminBenefitUsageStats).to receive(:new).and_call_original
      allow(self).to receive(:provider_status).and_return(503)
      allow(self).to receive(:provider_body).and_return("PRIVATE-PROVIDER-DIAGNOSTIC")
      before_counts = [ Order.count, Benefit.count, OrderBenefit.count ]

      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
      original_stats = response.parsed_body

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "code")).to eq("external_unavailable")
      expect(response.body).not_to include("PRIVATE-PROVIDER-DIAGNOSTIC", "test-only-key")

      get admin_benefit_usage_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(original_stats)
      expect([ Order.count, Benefit.count, OrderBenefit.count ]).to eq(before_counts)
      expect(attempts.size).to eq(1)
    end

    it "does not emit the key, prompt or provider response in application logs" do
      allow(self).to receive(:provider_status).and_return(503)
      allow(self).to receive(:provider_body).and_return("PRIVATE-PROVIDER-DIAGNOSTIC")
      output = StringIO.new
      original_logger = Rails.logger
      original_controller_logger = ActionController::Base.logger
      Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(output))
      ActionController::Base.logger = Rails.logger

      post admin_benefit_usage_summary_path, params: { month: "2032-04" }

      expect(response).to have_http_status(:service_unavailable)
      post admin_benefit_usage_summary_path,
           params: { month: "2032-04", prompt: "PRIVATE-REJECTED-PROMPT",
                     payload: { details: "PRIVATE-REJECTED-PAYLOAD" }, stats: { detail: "PRIVATE-REJECTED-STATS" },
                     api_key: "PRIVATE-REJECTED-KEY" }
      expect(response).to have_http_status(:bad_request)
      allow(self).to receive(:provider_status).and_return(200)
      allow(self).to receive(:provider_body).and_return(
        JSON.generate(type: "message", role: "assistant", stop_reason: "end_turn",
                      content: [ { type: "text", text: "PRIVATE-GENERATED-RESPONSE" } ])
      )
      post admin_benefit_usage_summary_path, params: { month: "2032-04" }
      expect(response).to have_http_status(:ok)
      expect(output.string).to include("Processing by")
      expect(output.string).not_to include("test-only-key", "Actuás como analista", "PRIVATE-PROVIDER-DIAGNOSTIC",
                                           "PRIVATE-GENERATED-RESPONSE", "PRIVATE-REJECTED-PROMPT",
                                           "PRIVATE-REJECTED-PAYLOAD", "PRIVATE-REJECTED-STATS",
                                           "PRIVATE-REJECTED-KEY", '"schema_version":1')
    ensure
      Rails.logger = original_logger
      ActionController::Base.logger = original_controller_logger
    end
  end
end
