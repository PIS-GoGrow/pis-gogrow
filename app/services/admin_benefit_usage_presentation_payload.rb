# frozen_string_literal: true

class AdminBenefitUsagePresentationPayload
  def initialize(stats:)
    @stats = stats
  end

  def to_h
    approved = AdminBenefitUsageAiPayload.new(stats: @stats).to_h
    benefits = @stats.fetch(:benefits)
    employees = @stats.fetch(:employees)
    closed = approved.fetch(:period).fetch(:closed)
    current_employees = integer(employees.fetch(:current_employees))

    {
      schema_version: approved.fetch(:schema_version),
      period: approved.fetch(:period),
      consumption: approved.fetch(:consumption),
      capacity: {
        monthly_quota_meals: (integer(benefits.fetch(:monthly_quota_meals)) unless closed),
        monthly_pending_reserved_meals: (integer(benefits.fetch(:monthly_pending_reserved_meals)) unless closed),
        monthly_available_meals: (integer(benefits.fetch(:monthly_available_meals)) unless closed)
      },
      participation: approved.fetch(:participation),
      employee_activity: {
        current_employees:,
        employees_with_confirmed_orders: integer(employees.fetch(:current_employees_with_confirmed_orders)),
        average_confirmed_meals_per_current_employee: average_confirmed_meals(current_employees)
      },
      trends: approved.fetch(:trends),
      anomalies: approved.fetch(:anomalies),
      warnings: approved.fetch(:warnings)
    }
  end

  private

  def integer(value)
    raise ArgumentError, "invalid count" unless value.nil? || value.is_a?(Integer)

    value
  end

  def average_confirmed_meals(current_employees)
    confirmed_meals = integer(@stats.fetch(:orders).fetch(:confirmed_meals))
    return if confirmed_meals.nil? || current_employees.zero?

    (confirmed_meals.to_d / current_employees).round(2).to_f
  end
end
