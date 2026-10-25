# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsageAiPayload do
  let(:change) { { reference: nil, difference: nil, percent: nil } }
  let(:months) do
    (1..4).map do |number|
      {
        month: Date.new(2032, number, 1), complete: true, confirmed_orders: 2,
        confirmed_meals: 3, monthly_subsidized_meals: 2,
        company_subsidy_amount: BigDecimal("1500.25"),
        changes: {
          confirmed_orders: change.dup, confirmed_meals: change.dup,
          monthly_subsidized_meals: change.dup, company_subsidy_amount: change.dup
        }
      }
    end
  end
  let(:stats) do
    {
      period: { month: Date.new(2032, 4, 1) },
      orders: { confirmed_orders: 2, confirmed_meals: 3, pending_orders: 1, pending_meals: 2 },
      benefits: {
        monthly_subsidized_meals: 2, confirmed_meals_without_monthly_subsidy: 1,
        monthly_pending_reserved_meals: 2, company_subsidy_amount: BigDecimal("1500.25"),
        monthly_quota_meals: 20, monthly_unused_closed_meals: nil
      },
      employees: {
        participation_percent: 50.0, eligibility: { eligible: 4 }, eligible_without_orders: 1,
        current_employees: 5
      },
      trends: { months: }, anomalies: [], warnings: []
    }
  end
  let(:payload) { described_class.new(stats:).to_h }

  it "selects aggregate consumption and keeps historical participation unknown" do
    expect(payload).to include(schema_version: 1, period: { month: "2032-04", closed: true })
    expect(payload[:consumption]).to eq(
      confirmed_orders: 2, confirmed_meals: 3, monthly_subsidized_meals: 2,
      confirmed_meals_without_monthly_subsidy: 1, company_subsidy_amount: "1500.25"
    )
    expect(payload[:participation]).to eq(percent: nil, eligible_employees: nil, eligible_without_orders: nil)
  end

  it "includes participation only for an open month with a trusted roster" do
    stats[:trends][:months].last[:complete] = false

    expect(payload[:participation]).to eq(percent: 50.0, eligible_employees: 4, eligible_without_orders: 1)
  end

  it "does not copy internal fields or personal information added anywhere in the source" do
    stats[:company_id] = 42
    stats[:employee] = { name: "Nombre privado", email: "privado@example.com" }
    stats[:orders][:individual_orders] = [ { address: "Dirección privada", bank_account: "123" } ]
    stats[:benefits][:personal_debt] = 100
    stats[:employees][:names] = [ "Nombre privado" ]
    stats[:trends][:months].last[:employee_id] = 7
    stats[:trends][:months].last[:changes][:confirmed_meals][:private_text] = "Secreto"

    serialized = JSON.generate(payload)
    expect(serialized).not_to include("Nombre privado", "privado@example.com", "Dirección privada",
                                      "bank_account", "personal_debt", "employee_id", "private_text", "Secreto")
    expect(payload.keys).to eq(%i[schema_version period consumption participation trends anomalies warnings])
  end

  it "preserves unknown values as JSON null and does not infer a historical roster" do
    stats[:benefits][:monthly_subsidized_meals] = nil
    stats[:benefits][:confirmed_meals_without_monthly_subsidy] = nil
    stats[:benefits][:company_subsidy_amount] = nil
    stats[:benefits][:monthly_quota_meals] = nil
    stats[:employees][:participation_percent] = nil
    stats[:employees][:eligible_without_orders] = nil
    stats[:trends][:months].last[:monthly_subsidized_meals] = nil

    parsed = JSON.parse(JSON.generate(payload))
    expect(parsed.dig("consumption", "monthly_subsidized_meals")).to be_nil
    expect(parsed.dig("consumption", "company_subsidy_amount")).to be_nil
    expect(parsed.dig("participation", "eligible_employees")).to be_nil
    expect(parsed.dig("participation", "percent")).to be_nil
    expect(parsed.dig("trends", 3, "monthly_subsidized_meals")).to be_nil
  end

  it "formats every period as YYYY-MM" do
    expect(payload[:trends].pluck(:month)).to eq(%w[2032-01 2032-02 2032-03 2032-04])
  end

  it "keeps decimal amounts as fixed precision strings in values and differences" do
    stats[:benefits][:company_subsidy_amount] = BigDecimal("12345678901234567890.12")
    stats[:trends][:months].last[:changes][:company_subsidy_amount] = {
      reference: BigDecimal("1000"), difference: BigDecimal("500.25"), percent: BigDecimal("50.025")
    }

    expect(payload.dig(:consumption, :company_subsidy_amount)).to eq("12345678901234567890.12")
    expect(payload.dig(:trends, 3, :changes, :company_subsidy_amount)).to eq(
      reference: "1000.00", difference: "500.25", percent: 50.025
    )
  end

  it "rejects more than four trend months instead of silently truncating them" do
    stats[:trends][:months].unshift(stats[:trends][:months].first.dup)

    expect { payload }.to raise_error(ArgumentError, "invalid trend length")
  end

  it "marks open months as partial and includes pending quantities separately" do
    stats[:trends][:months].last[:complete] = false
    stats[:trends][:months].last[:changes][:confirmed_meals] = { reference: 10, difference: -7, percent: -70 }

    expect(payload[:period]).to eq(month: "2032-04", closed: false)
    expect(payload.dig(:consumption, :pending)).to eq(orders: 1, meals: 2, monthly_reserved_meals: 2)
    expect(payload.dig(:trends, 3, :closed)).to be(false)
    expect(payload.dig(:trends, 3, :changes, :confirmed_meals, :difference)).to be_nil
    expect(payload.dig(:trends, 3, :changes, :confirmed_meals, :percent)).to be_nil
  end

  it "keeps only recognized historical warning codes and their necessary month" do
    stats[:warnings] = [
      { code: "historical_roster_incomplete", scope: "employees", detail: "Texto privado" },
      { code: "historical_trends_from_retained_records", scope: "trends" },
      { code: "trend_monthly_subsidy_unknown", scope: "trends", month: Date.new(2032, 3, 1), detail: "Privado" }
    ]

    expect(payload[:warnings]).to eq([
      { code: "historical_roster_incomplete" },
      { code: "historical_trends_from_retained_records" },
      { code: "trend_monthly_subsidy_unknown", month: "2032-03" }
    ])
  end

  it "copies only structured anomaly fields" do
    stats[:anomalies] = [
      { type: "increase", indicator: "confirmed_meals", month: Date.new(2032, 4, 1),
        current_value: 14, reference_value: 10, variation_percent: BigDecimal("40"),
        explanation: "Texto privado", employee_id: 7 }
    ]

    expect(payload[:anomalies]).to eq([
      { type: "increase", indicator: "confirmed_meals", month: "2032-04",
        current_value: 14, reference_value: 10, variation_percent: 40.0 }
    ])
  end

  it "rejects unknown warning or anomaly classifications" do
    stats[:warnings] = [ { code: "new_unreviewed_code", detail: "Texto privado" } ]
    expect { payload }.to raise_error(ArgumentError, "unknown warning")

    stats[:warnings] = []
    stats[:anomalies] = [ { type: "other", indicator: "confirmed_meals" } ]
    expect { payload }.to raise_error(ArgumentError, "unknown anomaly")
  end

  it "rejects non-finite percentages and oversized anomaly lists" do
    stats[:trends][:months].last[:complete] = false
    stats[:employees][:participation_percent] = Float::INFINITY
    expect { payload }.to raise_error(ArgumentError, "invalid percentage")

    stats[:employees][:participation_percent] = 50.0
    stats[:anomalies] = Array.new(7) { {} }
    expect { payload }.to raise_error(ArgumentError, "invalid anomaly length")
  end
end
