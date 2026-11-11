# frozen_string_literal: true

require "rails_helper"
require "fugit"

RSpec.describe BenefitUsageMonthlyCaptureJob do
  it "schedules one hourly capture on minute zero in Montevideo" do
    schedules = YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production")

    expect(schedules.fetch("benefit_usage_monthly_capture").fetch("schedule"))
      .to eq("every hour at minute 0 America/Montevideo")
    expect(schedules.fetch("benefit_usage_month_end_capture").fetch("schedule"))
      .to eq("every day at 11:55pm America/Montevideo")
    expect(schedules.values.pluck("schedule")).not_to include("every 15 minutes")
    expect(Fugit.parse(schedules.dig("benefit_usage_monthly_capture", "schedule"))).to be_a(Fugit::Cron)
    expect(Fugit.parse(schedules.dig("benefit_usage_month_end_capture", "schedule"))).to be_a(Fugit::Cron)
  end

  it "processes October at midnight without recalculating it from November data" do
    travel_to Time.zone.local(2032, 11, 1, 0, 0) do
      company = companies(:gogrow)
      october = Date.new(2032, 10, 1)
      snapshot = historical_snapshot(company:, month: october, status: :provisional, closed_at: nil,
                                     captured_at: Time.zone.local(2032, 10, 31, 23, 55))
      original_employees = snapshot.employees

      described_class.perform_now
      described_class.perform_now

      expect(snapshot.reload).to be_incomplete
      expect(snapshot.captured_at).to eq(Time.zone.local(2032, 10, 31, 23, 55))
      expect(snapshot.employees).to eq(original_employees)
      expect(snapshot.unavailable_reasons).to include("period" => "close_not_verified")
      expect(BenefitUsageMonthlySnapshot.where(company:, month: october).count).to eq(1)
      expect(BenefitUsageMonthlySnapshot.find_by!(company:, month: Date.new(2032, 11, 1))).to be_provisional
    end
  end

  it "recovers an omitted execution without inventing the missing month" do
    travel_to Time.zone.local(2032, 11, 2, 1, 0) do
      company = companies(:gogrow)
      september = Date.new(2032, 9, 1)
      snapshot = historical_snapshot(company:, month: september, status: :provisional, closed_at: nil)

      described_class.perform_now

      expect(snapshot.reload).to be_incomplete
      expect(BenefitUsageMonthlySnapshot.find_by(company:, month: Date.new(2032, 10, 1))).to be_nil
    end
  end

  it "preserves an already closed snapshot" do
    travel_to Time.zone.local(2032, 11, 1, 0, 0) do
      company = companies(:gogrow)
      october = Date.new(2032, 10, 1)
      snapshot = historical_snapshot(company:, month: october)

      described_class.perform_now

      expect(snapshot.reload).to be_closed
      expect(snapshot.unavailable_reasons).not_to include("period" => "close_not_verified")
    end
  end

  it "reports capture errors and leaves other companies available" do
    travel_to Time.zone.local(2032, 11, 4, 1, 0) do
      company = companies(:gogrow)
      other = Company.create!(name: "Otra empresa de prueba")
      month = Date.new(2032, 11, 1)
      allow(BenefitUsageMonthlyCapture).to receive(:new).and_call_original
      allow(BenefitUsageMonthlyCapture).to receive(:new).with(company:, month:).and_raise(StandardError, "falló")
      expect(Rails.error).to receive(:report).at_least(:once)

      described_class.perform_now

      expect(BenefitUsageMonthlySnapshot.find_by(company:, month:)).to be_nil
      expect(BenefitUsageMonthlySnapshot.find_by!(company: other, month:)).to be_provisional
    end
  end

  it "retries an unverified close later without blocking the new month's capture" do
    travel_to Time.zone.local(2032, 11, 1, 0, 0) do
      company = companies(:gogrow)
      october = Date.new(2032, 10, 1)
      snapshot = historical_snapshot(company:, month: october, status: :provisional, closed_at: nil)
      allow(BenefitUsageMonthlyClose).to receive(:new).and_call_original
      allow(BenefitUsageMonthlyClose).to receive(:new).with(company:, month: october).and_raise(StandardError, "falló")
      expect(Rails.error).to receive(:report).at_least(:once)

      described_class.perform_now

      expect(snapshot.reload).to be_provisional
      expect(BenefitUsageMonthlySnapshot.find_by!(company:, month: Date.new(2032, 11, 1))).to be_provisional
    end
  end
end
