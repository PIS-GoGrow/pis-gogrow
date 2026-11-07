# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitUsageMonthEndCaptureJob do
  it "closes the ending month at 23:55 without duplicating the snapshot" do
    travel_to Time.zone.local(2032, 10, 31, 23, 55) do
      company = companies(:gogrow)
      other = Company.create!(name: "Empresa de prueba")
      month = Date.new(2032, 10, 1)

      described_class.perform_now
      first = BenefitUsageMonthlySnapshot.find_by!(company:, month:)
      described_class.perform_now

      expect(first.reload).to be_closed
      expect(first.captured_at).to eq(Time.current)
      expect(first.closed_at).to eq(first.captured_at)
      expect(first.monthly_unused_closed_meals).to eq(first.monthly_available_meals)
      expect(BenefitUsageMonthlySnapshot.where(company:, month:).count).to eq(1)
      expect(BenefitUsageMonthlySnapshot.find_by!(company: other, month:)).to be_closed
    end
  end

  it "does not recalculate the previous month when its scheduled execution is delayed past midnight" do
    travel_to Time.zone.local(2032, 11, 1, 0, 1) do
      company = companies(:gogrow)
      month = Date.new(2032, 10, 1)
      snapshot = historical_snapshot(company:, month:, status: :provisional, closed_at: nil,
                                     captured_at: Time.zone.local(2032, 10, 31, 23, 0))

      described_class.perform_now

      expect(snapshot.reload).to be_provisional
      expect(snapshot.captured_at).to eq(Time.zone.local(2032, 10, 31, 23, 0))
      expect(BenefitUsageMonthlySnapshot.where(company:, month:).count).to eq(1)
    end
  end

  it "does not close a period before the final capture window" do
    travel_to Time.zone.local(2032, 10, 31, 23, 54) do
      described_class.perform_now

      expect(BenefitUsageMonthlySnapshot.where(month: Date.new(2032, 10, 1))).to be_empty
    end
  end

  it "reports a company failure and preserves its previous valid capture" do
    travel_to Time.zone.local(2032, 10, 31, 23, 55) do
      company = companies(:gogrow)
      month = Date.new(2032, 10, 1)
      old = historical_snapshot(company:, month:, status: :provisional, closed_at: nil,
                                captured_at: Time.zone.local(2032, 10, 31, 23, 0))
      allow(AdminBenefitUsageStats).to receive(:new).and_raise(StandardError, "captura fallida")
      expect(Rails.error).to receive(:report).at_least(:once)

      described_class.perform_now

      expect(old.reload.captured_at).to eq(Time.zone.local(2032, 10, 31, 23, 0))
      expect(old).to be_provisional
    end
  end
end
