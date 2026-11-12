# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitUsageSnapshotRetentionJob do
  it "keeps the current month and eleven predecessors, deleting only aggregate snapshots" do
    company = companies(:gogrow)
    oldest = Date.current.beginning_of_month << 11
    expired = historical_snapshot(company:, month: oldest.prev_month)
    retained = historical_snapshot(company:, month: oldest)
    other = Company.create!(name: "Otra empresa de prueba")
    other_expired = historical_snapshot(company: other, month: oldest.prev_month)
    other_retained = historical_snapshot(company: other, month: oldest)
    order_count = Order.count
    benefit_count = Benefit.count
    audit_count = AuditLog.count

    described_class.perform_now
    described_class.perform_now

    expect(BenefitUsageMonthlySnapshot.exists?(expired.id)).to be false
    expect(BenefitUsageMonthlySnapshot.exists?(retained.id)).to be true
    expect(BenefitUsageMonthlySnapshot.exists?(other_expired.id)).to be false
    expect(BenefitUsageMonthlySnapshot.exists?(other_retained.id)).to be true
    expect(Order.count).to eq(order_count)
    expect(Benefit.count).to eq(benefit_count)
    expect(AuditLog.count).to eq(audit_count)
  end
end
