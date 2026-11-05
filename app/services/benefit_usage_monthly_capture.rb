# frozen_string_literal: true

class BenefitUsageMonthlyCapture
  def initialize(company:, month: nil, at: Time.current)
    @company = company
    @at = at
    @month = month
  end

  def call
    month = @month || @at.in_time_zone("America/Montevideo").to_date.beginning_of_month
    raise ArgumentError, "only the current month can be captured" unless month == @at.in_time_zone("America/Montevideo").to_date.beginning_of_month

    @company.with_lock do
      raise ArgumentError, "period changed during capture" unless month == Date.current.beginning_of_month

      snapshot = BenefitUsageMonthlySnapshot.find_or_initialize_by(company: @company, month:)
      return snapshot if snapshot.closed?

      stats = AdminBenefitUsageStats.new(company: @company, month:).to_h
      benefits = stats.fetch(:benefits)
      employees = stats.fetch(:employees)
      eligibility = employees.fetch(:eligibility)
      complete_eligibility = eligibility.fetch(:unknown).zero?
      reasons = {}

      attributes = {
        status: :provisional, calculation_version: 1,
        employees: employees.fetch(:current_employees),
        eligible_employees: (eligibility.fetch(:eligible) if complete_eligibility),
        unknown_eligibility_employees: eligibility.fetch(:unknown),
        employees_with_confirmed_orders: employees.fetch(:current_employees_with_confirmed_orders),
        eligible_with_confirmed_orders: (employees.fetch(:known_eligible_with_confirmed_orders) if complete_eligibility),
        eligible_without_orders: employees.fetch(:eligible_without_orders),
        monthly_quota_meals: benefits.fetch(:monthly_quota_meals),
        monthly_subsidized_meals: benefits.fetch(:monthly_subsidized_meals),
        monthly_pending_reserved_meals: benefits.fetch(:monthly_pending_reserved_meals),
        monthly_available_meals: benefits.fetch(:monthly_available_meals),
        monthly_unused_closed_meals: nil,
        confirmed_orders: stats.dig(:orders, :confirmed_orders),
        confirmed_meals: stats.dig(:orders, :confirmed_meals),
        confirmed_meals_without_monthly_subsidy: benefits.fetch(:confirmed_meals_without_monthly_subsidy),
        pending_orders: stats.dig(:orders, :pending_orders),
        pending_meals: stats.dig(:orders, :pending_meals),
        company_subsidy_amount: benefits.fetch(:company_subsidy_amount)
      }
      reasons["eligible_employees"] = "eligibility_unknown" unless complete_eligibility
      reasons["eligible_with_confirmed_orders"] = "eligibility_unknown" unless complete_eligibility
      reasons["participation_percent"] = complete_eligibility ? "no_eligible_employees" : "eligibility_unknown" if attributes[:eligible_employees].to_i.zero? || !complete_eligibility
      reasons["average_confirmed_meals_per_employee"] = "no_employees" if attributes[:employees].zero?
      reasons["monthly_utilization_percent"] = "quota_unknown_or_zero" if attributes[:monthly_quota_meals].to_i.zero?
      attributes.each do |name, value|
        reasons[name.to_s] ||= "source_unavailable" if value.nil? && name != :monthly_unused_closed_meals
      end
      reasons["monthly_unused_closed_meals"] = "period_open"
      captured_at = Time.current
      raise ArgumentError, "period changed during capture" unless captured_at.in_time_zone("America/Montevideo").to_date.beginning_of_month == month

      snapshot.assign_attributes(attributes.merge(captured_at:, unavailable_reasons: reasons))
      snapshot.save!
      snapshot
    end
  end
end
