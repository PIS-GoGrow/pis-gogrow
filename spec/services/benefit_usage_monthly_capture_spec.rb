# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitUsageMonthlyCapture do
  let(:company) { companies(:gogrow) }
  let(:month) { Date.current.beginning_of_month }

  it "captures the live month once and updates the same provisional record" do
    first = described_class.new(company:).call
    expect(first).to be_provisional
    expect(first.month).to eq(month)
    expect(first.employees).to eq(company.consumers.count)
    expect(first.unavailable_reasons).to include("monthly_unused_closed_meals" => "period_open")

    second = described_class.new(company:).call
    expect(second.id).to eq(first.id)
    expect(BenefitUsageMonthlySnapshot.where(company:, month:).count).to eq(1)
  end

  it "does not recalculate an old month from today's roster" do
    old = Date.current.beginning_of_month.prev_month
    expect { described_class.new(company:, at: old.end_of_month.end_of_day).call }.to raise_error(ArgumentError)
    expect(BenefitUsageMonthlySnapshot.find_by(company:, month: old)).to be_nil
  end

  it "never overwrites an already closed period" do
    closed = historical_snapshot(company:, month:)
    expect(AdminBenefitUsageStats).not_to receive(:new)

    expect(described_class.new(company:).call.id).to eq(closed.id)
    expect(closed.reload).to be_closed
    expect(closed.monthly_quota_meals).to eq(160)
  end

  it "preserves a previously captured employee count after the roster changes" do
    snapshot = described_class.new(company:).call
    captured = snapshot.employees
    user = User.create!(name: "Empleado de prueba", email: "snapshot-new@example.com", password: "secret-password-123")
    Consumer.create!(user:, company:, onboarding_date: Date.current)

    expect(company.consumers.count).to eq(captured + 1)
    expect(snapshot.reload.employees).to eq(captured)
  end

  it "marks an unverified prior period incomplete instead of falsely closing it" do
    old = historical_snapshot(company:, month: month.prev_month, status: :provisional, closed_at: nil)

    BenefitUsageMonthlyCaptureJob.perform_now

    expect(old.reload).to be_incomplete
    expect(old.unavailable_reasons).to include("period" => "close_not_verified")
  end
end
