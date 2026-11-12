# frozen_string_literal: true

class BenefitUsageMonthlyClose
  def initialize(company:, month:)
    @company = company
    @month = month
  end

  def call
    raise ArgumentError, "only past periods can be processed" unless @month < Date.current.beginning_of_month

    @company.with_lock do
      snapshot = BenefitUsageMonthlySnapshot.find_by(company: @company, month: @month)
      return unless snapshot
      return snapshot unless snapshot.provisional?

      snapshot.update!(status: :incomplete, unavailable_reasons: snapshot.unavailable_reasons.merge(
        "period" => "close_not_verified", "monthly_unused_closed_meals" => "close_not_verified"
      ))
      snapshot
    end
  end
end
