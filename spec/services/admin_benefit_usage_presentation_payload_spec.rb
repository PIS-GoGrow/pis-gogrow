# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsagePresentationPayload do
  let(:month) { Date.new(2032, 4, 1) }
  let(:change) { { reference: nil, difference: nil, percent: nil } }
  let(:stats) do
    {
      period: { month: },
      orders: { confirmed_orders: 2, confirmed_meals: 3, pending_orders: 1, pending_meals: 2 },
      benefits: {
        monthly_subsidized_meals: 2, confirmed_meals_without_monthly_subsidy: 1,
        monthly_pending_reserved_meals: 1, monthly_quota_meals: 20, monthly_available_meals: 17,
        company_subsidy_amount: BigDecimal("1500.25"), known_eligible_monthly_quota_meals: 30,
        monthly_unused_closed_meals: nil
      },
      employees: {
        participation_percent: 50.0, eligibility: { eligible: 4 }, eligible_without_orders: 1,
        current_employees: 4, current_employees_with_confirmed_orders: 2
      },
      trends: { months: [
        { month:, complete: false, confirmed_orders: 2, confirmed_meals: 3,
          monthly_subsidized_meals: 2, company_subsidy_amount: BigDecimal("1500.25"),
          changes: { confirmed_orders: change, confirmed_meals: change,
                     monthly_subsidized_meals: change, company_subsidy_amount: change } }
      ] },
      anomalies: [], warnings: [ { code: "open_month_partial", scope: "trends" } ]
    }
  end
  let(:payload) { described_class.new(stats:).to_h }

  it "keeps the AI fields and adds only the approved presentation blocks" do
    original = AdminBenefitUsageAiPayload.new(stats:).to_h

    expect(payload.except(:employee_activity)).to eq(original)
    expect(payload.keys).to eq(%i[schema_version period consumption capacity participation employee_activity trends
                                  anomalies warnings])
    expect(payload[:capacity].keys).to eq(%i[monthly_quota_meals monthly_pending_reserved_meals monthly_available_meals])
    expect(payload[:capacity]).to eq(monthly_quota_meals: 20, monthly_pending_reserved_meals: 1,
                                     monthly_available_meals: 17)
    expect(payload[:employee_activity]).to eq(
      current_employees: 4, employees_with_confirmed_orders: 2,
      average_confirmed_meals_per_current_employee: 0.75
    )
    expect(payload.dig(:consumption, :pending)).to eq(orders: 1, meals: 2, monthly_reserved_meals: 1)
  end

  [ :monthly_quota_meals, :monthly_pending_reserved_meals, :monthly_available_meals ].each do |field|
    it "keeps an unknown #{field} as JSON null without changing other capacity fields" do
      stats[:benefits][field] = nil

      expect(JSON.parse(JSON.generate(payload)).dig("capacity", field.to_s)).to be_nil
      expect(payload[:capacity].except(field).values).to all(be_a(Integer))
    end
  end

  it "does not expose historical quota, reservations or available balance" do
    stats[:trends][:months].last[:complete] = true

    expect(payload[:period]).to eq(month: "2032-04", closed: true)
    expect(payload[:capacity].values).to eq([ nil, nil, nil ])
    expect(payload.dig(:consumption, :pending)).to be_nil
    expect(payload.dig(:participation, :percent)).to be_nil
    expect(payload[:employee_activity]).to eq(
      current_employees: 4, employees_with_confirmed_orders: 2,
      average_confirmed_meals_per_current_employee: 0.75
    )
  end

  it "averages confirmed meals over every current employee with at most two decimals" do
    stats[:orders][:confirmed_meals] = 10
    stats[:employees][:current_employees] = 3

    expect(payload.dig(:employee_activity, :average_confirmed_meals_per_current_employee)).to eq(3.33)
  end

  it "returns zero when there are current employees but no confirmed meals" do
    stats[:orders][:confirmed_meals] = 0

    expect(payload.dig(:employee_activity, :average_confirmed_meals_per_current_employee)).to eq(0.0)
  end

  it "leaves the average unknown without current employees or reliable confirmed meals" do
    stats[:employees][:current_employees] = 0
    expect(payload.dig(:employee_activity, :average_confirmed_meals_per_current_employee)).to be_nil

    stats[:employees][:current_employees] = 4
    stats[:orders][:confirmed_meals] = nil
    expect(described_class.new(stats:).to_h.dig(:employee_activity,
                                                :average_confirmed_meals_per_current_employee)).to be_nil
  end

  it "preserves decimal money, trends, anomalies and controlled warnings" do
    stats[:benefits][:company_subsidy_amount] = BigDecimal("12345678901234567890.12")
    stats[:anomalies] = [ { type: "increase", indicator: "confirmed_meals", month:,
                            current_value: 13, reference_value: 10, variation_percent: BigDecimal("30.0") } ]
    stats[:warnings] << { code: "benefit_consumer_mismatch", scope: "benefits", detail: "private" }

    expect(payload.dig(:consumption, :company_subsidy_amount)).to eq("12345678901234567890.12")
    expect(payload.dig(:trends, 0, :month)).to eq("2032-04")
    expect(payload[:anomalies].sole).to include(type: "increase", indicator: "confirmed_meals", current_value: 13)
    expect(payload[:warnings]).to include(code: "benefit_consumer_mismatch")
    expect(JSON.generate(payload)).not_to include("private")
  end

  it "excludes personal records and arbitrary internal fields from every output block" do
    stats[:employee] = { name: "PRIVATE-NAME", email: "private@example.test" }
    stats[:orders][:individual_orders] = [ { address: "PRIVATE-ADDRESS" } ]
    stats[:benefits][:consumer_id] = 123
    stats[:benefits][:known_eligible_with_known_quota] = 8
    stats[:employees][:names] = [ "PRIVATE-NAME" ]
    stats[:trends][:months].first[:order_id] = 456

    serialized = JSON.generate(payload)
    expect(serialized).not_to include("PRIVATE-", "@example.test", "consumer_id", "order_id",
                                      "individual_orders", "known_eligible_with_known_quota")
  end

  it "rejects a non-integer capacity value instead of silently coercing it" do
    stats[:benefits][:monthly_available_meals] = "17"

    expect { payload }.to raise_error(ArgumentError, "invalid count")
  end
end
