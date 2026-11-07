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

  it "atomically replaces the provisional capture with an operational close" do
    travel_to Time.zone.local(2032, 10, 31, 23, 55) do
      stats = AdminBenefitUsageStats.new(company:, month: Date.current.beginning_of_month).to_h
      stats[:orders][:confirmed_meals] = 40
      stats[:benefits].merge!(monthly_quota_meals: 160, monthly_subsidized_meals: 40,
                             monthly_pending_reserved_meals: 0, monthly_available_meals: 120)
      allow(AdminBenefitUsageStats).to receive(:new).and_return(instance_double(AdminBenefitUsageStats, to_h: stats))
      provisional = described_class.new(company:).call
      closed = described_class.new(company:, final: true).call

      expect(closed.id).to eq(provisional.id)
      expect(closed).to be_closed
      expect(closed.closed_at).to eq(closed.captured_at)
      expect(closed.monthly_unused_closed_meals).to eq(120)
      expect(closed.unavailable_reasons).not_to have_key("monthly_unused_closed_meals")
      expect(described_class.new(company:).call.id).to eq(closed.id)
      expect(closed.reload).to be_closed
    end
  end

  it "keeps the close value unknown when the live quota cannot be verified" do
    travel_to Time.zone.local(2032, 10, 31, 23, 55) do
      stats = AdminBenefitUsageStats.new(company:, month: Date.current.beginning_of_month).to_h
      stats[:benefits][:monthly_available_meals] = nil
      allow(AdminBenefitUsageStats).to receive(:new).and_return(instance_double(AdminBenefitUsageStats, to_h: stats))

      snapshot = described_class.new(company:, final: true).call

      expect(snapshot).to be_closed
      expect(snapshot.monthly_unused_closed_meals).to be_nil
      expect(snapshot.unavailable_reasons).to include("monthly_unused_closed_meals" => "source_unavailable")
    end
  end

  it "preserves the earlier capture if the final calculation fails" do
    travel_to Time.zone.local(2032, 10, 31, 23, 55) do
      earlier = described_class.new(company:).call
      original_time = earlier.captured_at
      allow(AdminBenefitUsageStats).to receive(:new).and_raise(StandardError, "capture failed")

      expect { described_class.new(company:, final: true).call }.to raise_error(StandardError, "capture failed")
      expect(earlier.reload).to be_provisional
      expect(earlier.captured_at).to eq(original_time)
    end
  end

  it "rejects a final capture after midnight without changing the previous period" do
    travel_to Time.zone.local(2032, 11, 1, 0, 1) do
      expect { described_class.new(company:, month: Date.new(2032, 10, 1), final: true).call }
        .to raise_error(ArgumentError)
      expect(BenefitUsageMonthlySnapshot.where(company:, month: Date.new(2032, 10, 1))).to be_empty
    end
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
