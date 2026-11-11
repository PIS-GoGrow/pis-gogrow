# frozen_string_literal: true

class BenefitUsageMonthlyCaptureJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current.in_time_zone("America/Montevideo")
    month = now.to_date.beginning_of_month

    Company.find_each do |company|
      company.benefit_usage_monthly_snapshots.provisional.where(month: ...month).pluck(:month).each do |old_month|
        begin
          BenefitUsageMonthlyClose.new(company:, month: old_month).call
        rescue => error
          Rails.error.report(error, context: { company_id: company.id, month: old_month }, handled: true)
        end
      end

      if now.day == 1 && now.hour.zero? && !company.benefit_usage_monthly_snapshots.exists?(month: month.prev_month)
        Rails.logger.warn("Benefit usage snapshot missing for company #{company.id}, month #{month.prev_month}")
      end

      begin
        BenefitUsageMonthlyCapture.new(company:, month:).call
      rescue => error
        Rails.error.report(error, context: { company_id: company.id, month: }, handled: true)
      end
    end
  end
end
