# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitUsageMonthlyClose do
  it "preserves captured values and records why they cannot represent an exact close" do
    travel_to Time.zone.local(2032, 11, 1, 0, 0) do
      company = companies(:gogrow)
      month = Date.new(2032, 10, 1)
      snapshot = historical_snapshot(company:, month:, status: :provisional, closed_at: nil,
                                     captured_at: Time.zone.local(2032, 10, 31, 23, 55), monthly_unused_closed_meals: nil)
      expect(AdminBenefitUsageStats).not_to receive(:new)

      result = described_class.new(company:, month:).call

      expect(result).to be_incomplete
      expect(result.captured_at).to eq(Time.zone.local(2032, 10, 31, 23, 55))
      expect(result.monthly_quota_meals).to eq(160)
      expect(result.monthly_unused_closed_meals).to be_nil
      expect(result.unavailable_reasons).to include("period" => "close_not_verified",
                                                    "monthly_unused_closed_meals" => "close_not_verified")
      expect(described_class.new(company:, month:).call.id).to eq(snapshot.id)
    end
  end

  it "rejects closing the current month" do
    expect { described_class.new(company: companies(:gogrow), month: Date.current.beginning_of_month).call }
      .to raise_error(ArgumentError)
  end
end
