# frozen_string_literal: true

class BenefitUsageSnapshotCorrection
  METRICS = %i[
    employees eligible_employees unknown_eligibility_employees employees_with_confirmed_orders
    eligible_with_confirmed_orders eligible_without_orders monthly_quota_meals monthly_subsidized_meals
    monthly_pending_reserved_meals monthly_available_meals monthly_unused_closed_meals confirmed_orders
    confirmed_meals confirmed_meals_without_monthly_subsidy pending_orders pending_meals company_subsidy_amount
    unavailable_reasons
  ].freeze

  def initialize(snapshot:, user:, reason:, changes:)
    @snapshot = snapshot
    @user = user
    @reason = reason
    @changes = changes
  end

  def call
    raise ArgumentError, "reason required" if @reason.blank?
    raise ArgumentError, "user required" unless @user&.persisted?
    raise ArgumentError, "invalid correction" unless @changes.present? && (@changes.keys.map(&:to_sym) - METRICS).empty?

    @snapshot.with_lock do
      raise ArgumentError, "only closed snapshots can be corrected" unless @snapshot.closed?

      before = @snapshot.attributes.slice(*@changes.keys.map(&:to_s))
      @snapshot.correction_authorized = true
      @snapshot.update!(@changes)
      AuditLog.create!(auditable: @snapshot, user: @user, changeset: {
        action: "benefit_usage_snapshot_correction", reason: @reason, before:, after: @snapshot.attributes.slice(*before.keys)
      })
      @snapshot
    ensure
      @snapshot.correction_authorized = false
    end
  end
end
