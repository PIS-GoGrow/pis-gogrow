# frozen_string_literal: true

class BenefitUsageSnapshotRetentionJob < ApplicationJob
  queue_as :default

  def perform
    oldest = Date.current.beginning_of_month << 11
    BenefitUsageMonthlySnapshot.where(month: ...oldest).delete_all
  end
end
