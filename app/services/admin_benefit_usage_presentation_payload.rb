# frozen_string_literal: true

class AdminBenefitUsagePresentationPayload
  def initialize(stats:)
    @stats = stats
  end

  def to_h
    approved = AdminBenefitUsageAiPayload.new(stats: @stats).to_h
    benefits = @stats.fetch(:benefits)
    closed = approved.fetch(:period).fetch(:closed)

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
end
