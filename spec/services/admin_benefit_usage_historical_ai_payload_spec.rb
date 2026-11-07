# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsageAiPayload do
  let(:company) { companies(:gogrow) }

  around { |example| travel_to(Time.zone.local(2026, 11, 4, 12)) { example.run } }

  def payload_for(month)
    history = AdminBenefitUsageHistory.new(company:, month:).to_h
    described_class.new(history:).to_h
  end

  it "sends September and October operational closes with a compatible comparison only" do
    ibp_041_2026_snapshots(company:)
    september = payload_for(Date.new(2026, 9, 1))
    october = payload_for(Date.new(2026, 10, 1))

    expect(september[:period]).to include(month: "2026-09", state: "closed", source: "historical_snapshot",
                                          captured_at: Time.zone.local(2026, 9, 30, 23, 55).iso8601)
    expect(september[:metrics]).to include(employees: 38, eligible_employees: 36,
                                           eligible_with_confirmed_orders: 12, monthly_quota_meals: 720,
                                           confirmed_meals: 28, monthly_subsidized_meals: 28,
                                           participation_percent: 33.33)
    expect(september[:comparison]).to be_nil
    expect(october[:metrics]).to include(employees: 40, eligible_employees: 38,
                                         eligible_with_confirmed_orders: 16, monthly_quota_meals: 760,
                                         confirmed_meals: 44, monthly_subsidized_meals: 40,
                                         participation_percent: 42.11, monthly_unused_closed_meals: 716)
    expect(october[:comparison]).to include(from: "2026-09", to: "2026-10", quality: "verified_close")
    expect(october.dig(:comparison, :changes, :participation_percent)).to include(
      difference: nil, difference_points: 8.77, percent: 26.32
    )
    expect(october[:limitations]).to be_empty
  end

  it "uses verified closed values and excludes incompatible comparisons" do
    ibp_041_verified_close(company:)
    ibp_041_incomplete_snapshot(company:)
    august = payload_for(Date.new(2026, 8, 1))
    september = payload_for(Date.new(2026, 9, 1))

    expect(august[:period]).to include(state: "closed", source: "historical_snapshot")
    expect(august.dig(:metrics, :monthly_unused_closed_meals)).to eq(640)
    expect(september[:comparison]).to be_nil
  end

  it "keeps unknown historical roster and quota values unknown during reconstruction" do
    history = AdminBenefitUsageHistory.new(company:, month: Date.new(2026, 7, 1)).to_h
    history[:metrics][:confirmed_orders] = 1
    history[:metrics][:confirmed_meals] = 2
    history[:metrics][:employee_email] = "private@example.test"
    history[:unavailable_reasons]["employees"] = "private@example.test"
    history[:comparisons] << { to: "2026-07", from: "2026-06", quality: "not_comparable", changes: {} }

    payload = described_class.new(history:).to_h

    expect(payload[:period]).to include(state: "missing_snapshot", source: "historical_reconstruction",
                                        captured_at: nil)
    expect(payload[:metrics]).to include(employees: nil, eligible_employees: nil, monthly_quota_meals: nil,
                                         confirmed_orders: 1, confirmed_meals: 2)
    expect(payload[:comparison]).to be_nil
    expect(JSON.generate(payload)).not_to include("private@example.test", "employee_email")
  end

  it "rejects a reconstruction with no verifiable activity and snapshots with no useful metrics" do
    history = AdminBenefitUsageHistory.new(company:, month: Date.new(2026, 7, 1)).to_h
    expect { described_class.new(history:).to_h }.to raise_error(described_class::InsufficientData)

    ibp_041_2026_snapshots(company:)
    history = AdminBenefitUsageHistory.new(company:, month: Date.new(2026, 10, 1)).to_h
    history[:metrics].transform_values! { nil }
    expect { described_class.new(history:).to_h }.to raise_error(described_class::InsufficientData)
  end

  it "copies no unapproved individual or financial fields from a snapshot" do
    ibp_041_2026_snapshots(company:)
    history = AdminBenefitUsageHistory.new(company:, month: Date.new(2026, 10, 1)).to_h
    history[:metrics][:employee_name] = "Nombre privado"
    history[:metrics][:bank_account] = "123456"
    history[:period][:company_id] = company.id
    history[:comparisons].last[:changes][:employee_email] = "private@example.test"
    history[:unavailable_reasons]["private_note"] = "private@example.test"

    serialized = JSON.generate(described_class.new(history:).to_h)

    expect(serialized).not_to include("Nombre privado", "bank_account", "123456", "company_id",
                                      "employee_email", "private@example.test", "private_note")
  end
end
