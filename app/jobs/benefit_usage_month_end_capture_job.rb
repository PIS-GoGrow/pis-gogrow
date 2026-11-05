# frozen_string_literal: true

class BenefitUsageMonthEndCaptureJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current.in_time_zone("America/Montevideo")
    return unless now.to_date == now.to_date.end_of_month

    month = now.to_date.beginning_of_month
    Company.find_each do |company|
      BenefitUsageMonthlyCapture.new(company:, month:).call
    rescue => error
      Rails.error.report(error, context: { company_id: company.id, month: }, handled: true)
    end
  end
end
