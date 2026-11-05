# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsageHistory do
  let(:company) { companies(:gogrow) }

  around { |example| travel_to(Time.zone.local(2026, 11, 4, 12)) { example.run } }

  it "reads the fictional September and October snapshots with their own employee and meal counts" do
    september, october = ibp_041_2026_snapshots(company:)
    september_data = described_class.new(company:, month: september.month).to_h
    october_data = described_class.new(company:, month: october.month).to_h

    expect(september_data[:period]).to include(source: "historical_snapshot", state: "incomplete", fictional: true,
                                               captured_at: Time.zone.local(2026, 9, 30, 23, 55).iso8601)
    expect(september_data[:metrics]).to include(employees: 38, eligible_employees: 36,
                                                eligible_with_confirmed_orders: 12, monthly_quota_meals: 720,
                                                confirmed_meals: 28, monthly_subsidized_meals: 28,
                                                participation_percent: BigDecimal("33.33"))
    expect(october_data[:metrics]).to include(employees: 40, eligible_employees: 38,
                                              eligible_with_confirmed_orders: 16, monthly_quota_meals: 760,
                                              confirmed_meals: 44, monthly_subsidized_meals: 40,
                                              confirmed_meals_without_monthly_subsidy: 4,
                                              participation_percent: BigDecimal("42.11"))
    expect(october_data[:metrics][:monthly_unused_closed_meals]).to be_nil
    expect(october_data[:unavailable_reasons]).to include("period" => "close_not_verified",
                                                         "monthly_unused_closed_meals" => "close_not_verified")
  end

  it "compares like-for-like 23:55 captures and labels percentage points separately" do
    ibp_041_2026_snapshots(company:)
    comparison = described_class.new(company:, month: Date.new(2026, 10, 1)).to_h[:comparisons].last

    expect(comparison).to include(from: "2026-09", to: "2026-10", quality: "capture_only")
    expect(comparison.dig(:changes, :confirmed_meals)).to include(reference: 28, current: 44, difference: 16,
                                                                  percent: BigDecimal("57.14"))
    expect(comparison.dig(:changes, :monthly_quota_meals)).to include(reference: 720, current: 760,
                                                                      difference: 40, percent: BigDecimal("5.56"))
    expect(comparison.dig(:changes, :participation_percent)).to include(
      reference: BigDecimal("33.33"), current: BigDecimal("42.11"),
      difference: nil, difference_points: BigDecimal("8.77"), percent: BigDecimal("26.32")
    )
    expect(comparison.dig(:changes, :company_subsidy_amount)).to include(reference: BigDecimal("4200"),
                                                                         current: BigDecimal("6600"),
                                                                         difference: BigDecimal("2400"),
                                                                         percent: BigDecimal("57.14"))
    expect(comparison.dig(:changes, :eligible_with_confirmed_orders)).to include(reference: 12, current: 16,
                                                                                 difference: 4)
  end

  it "does not compare an incomplete capture with a verified close" do
    ibp_041_verified_close(company:)
    ibp_041_2026_snapshots(company:)
    comparison = described_class.new(company:, month: Date.new(2026, 9, 1)).to_h[:comparisons].last

    expect(comparison[:quality]).to eq("not_comparable")
    expect(comparison.dig(:changes, :confirmed_meals, :difference)).to be_nil
  end

  it "keeps a missing snapshot separate from current-roster reconstruction" do
    result = described_class.new(company:, month: Date.new(2026, 7, 1)).to_h

    expect(result[:period]).to include(source: "historical_reconstruction", state: "missing_snapshot",
                                       captured_at: nil, fictional: false)
    expect(result[:metrics]).to include(employees: nil, eligible_employees: nil, monthly_quota_meals: nil,
                                        participation_percent: nil, monthly_unused_closed_meals: nil)
    expect(result[:unavailable_reasons]).to include("period" => "historical_snapshot_missing",
                                                   "reconstructed_orders" => "retained_records_current_roster")
  end

  it "keeps incomplete metric values unknown and does not derive percentages from missing denominators" do
    september, = ibp_041_2026_snapshots(company:)
    september.update!(eligible_employees: nil, eligible_with_confirmed_orders: nil,
                      unavailable_reasons: { "eligible_employees" => "eligibility_unknown" })

    metrics = described_class.new(company:, month: september.month).to_h.fetch(:metrics)

    expect(metrics[:eligible_employees]).to be_nil
    expect(metrics[:participation_percent]).to be_nil
  end

  it "does not expose arbitrary text stored as an availability reason" do
    september, = ibp_041_2026_snapshots(company:)
    september.update!(unavailable_reasons: { "employees" => "private@example.test" })

    result = described_class.new(company:, month: september.month).to_h

    expect(result[:unavailable_reasons]).to include("employees" => "source_unavailable")
    expect(JSON.generate(result)).not_to include("private@example.test")
  end

  it "does not read another company's snapshot or a month outside the twelve-month window" do
    ibp_041_2026_snapshots(company:)
    other = Company.create!(name: "Empresa de pruebas B")

    expect(described_class.new(company: other, month: Date.new(2026, 10, 1)).to_h.dig(:period, :state))
      .to eq("missing_snapshot")
    expect { described_class.new(company:, month: Date.new(2025, 11, 1)).to_h }.to raise_error(ArgumentError)
  end

  it "refuses to create fictional scenarios outside test" do
    allow(Rails.env).to receive(:test?).and_return(false)

    expect { ibp_041_2026_snapshots(company:) }.to raise_error(/test environment/)
    expect(BenefitUsageMonthlySnapshot.where(company:, fictional: true)).to be_empty
  end

  it "distinguishes a controlled verified close and avoids percentages with a zero reference" do
    closed = ibp_041_verified_close(company:)
    historical_snapshot(company:, month: closed.month.prev_month, confirmed_orders: 0, confirmed_meals: 0,
                        monthly_subsidized_meals: 0, employees_with_confirmed_orders: 0,
                        eligible_with_confirmed_orders: 0, eligible_without_orders: 8,
                        monthly_available_meals: 160, monthly_unused_closed_meals: 160,
                        company_subsidy_amount: 0)
    result = described_class.new(company:, month: closed.month).to_h

    expect(result[:period]).to include(state: "closed", fictional: true)
    expect(result.dig(:metrics, :monthly_unused_closed_meals)).to eq(640)
    expect(result[:comparisons].last[:quality]).to eq("verified_close")
    expect(result[:comparisons].last.dig(:changes, :confirmed_meals, :percent)).to be_nil
  end
end
