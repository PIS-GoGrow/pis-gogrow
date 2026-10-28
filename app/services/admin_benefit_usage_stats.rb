# frozen_string_literal: true

class AdminBenefitUsageStats
  def initialize(company:, month:)
    @company = company
    @month = month.to_date.beginning_of_month
  end

  def to_h
    confirmed = orders.confirmed
    pending = orders.pending
    confirmed_meals = confirmed_meals_for(confirmed)
    monthly_benefits = Benefit.monthly.where(consumer_id: consumers.select(:id))
                              .where(benefit_configuration_id: @company.benefit_configurations.select(:id))
    confirmed_uses = monthly_uses_for(confirmed, monthly_benefits)
    pending_uses = monthly_uses_for(pending, monthly_benefits)
    missing_confirmed = missing_benefit_records?(confirmed)
    missing_pending = missing_benefit_records?(pending)
    invalid_confirmed_uses = invalid_monthly_uses?(confirmed, confirmed_uses)
    invalid_pending_uses = invalid_monthly_uses?(pending, pending_uses)
    mismatched_confirmed_uses = mismatched_benefit_uses?(confirmed)
    mismatched_pending_uses = mismatched_benefit_uses?(pending)
    company_subsidy_amount = company_subsidy_for(confirmed)

    consumer_dates = consumers.pluck(:id, :onboarding_date).to_h
    eligibility, quotas = classify_eligibility(consumer_dates, monthly_benefits)
    confirmed_by_consumer = uses_by_consumer(confirmed, monthly_benefits)
    pending_by_consumer = uses_by_consumer(pending, monthly_benefits)
    eligible_ids = eligibility.select { |_id, state| state == :eligible }.keys
    known_quota = quotas.values.sum
    full_coverage = eligibility.values.none?(:unknown) && quotas.size == eligible_ids.size
    within_quota = quotas.all? do |consumer_id, quota|
      confirmed_by_consumer.fetch(consumer_id, 0) + pending_by_consumer.fetch(consumer_id, 0) <= quota
    end
    uses_outside_eligibility = (confirmed_by_consumer.keys | pending_by_consumer.keys).any? { eligibility[it] != :eligible }
    reliable_quota = full_coverage && within_quota && !uses_outside_eligibility &&
                     !missing_confirmed && !missing_pending && !invalid_confirmed_uses && !invalid_pending_uses &&
                     !mismatched_confirmed_uses && !mismatched_pending_uses

    employee_count = consumer_dates.size
    employees_with_orders = orders.distinct.count(:consumer_id)
    consumers_with_orders = orders.distinct.pluck(:consumer_id).to_set
    consumers_with_confirmed = confirmed.distinct.pluck(:consumer_id).to_set
    eligible_with_confirmed = eligible_ids.count { consumers_with_confirmed.include?(it) }
    eligible_without_orders = eligible_ids.count { !consumers_with_orders.include?(it) }
    current_month = @month == Date.current.beginning_of_month
    closed_month = @month < Date.current.beginning_of_month
    complete_current_roster = current_month && full_coverage

    warnings = [ { code: "employee_counts_use_current_roster", scope: "employees" } ]
    warnings << { code: "historical_roster_incomplete", scope: "employees" } if closed_month
    warnings << { code: "historical_status_at_close_unavailable", scope: "benefits" } if closed_month
    warnings << { code: "eligibility_unknown", scope: "employees", count: eligibility.values.count(:unknown) } if eligibility.value?(:unknown)
    warnings << { code: "monthly_quota_unknown", scope: "benefits", count: eligible_ids.size - quotas.size } if quotas.size < eligible_ids.size
    warnings << { code: "historical_discounts_without_benefit_records", scope: "benefits" } if missing_confirmed
    warnings << { code: "pending_discounts_without_benefit_records", scope: "benefits" } if missing_pending
    warnings << { code: "monthly_benefit_units_exceed_order_amount", scope: "benefits" } if invalid_confirmed_uses || invalid_pending_uses
    warnings << { code: "benefit_consumer_mismatch", scope: "benefits" } if mismatched_confirmed_uses || mismatched_pending_uses
    warnings << { code: "monthly_usage_exceeds_quota", scope: "benefits" } unless within_quota
    warnings << { code: "monthly_usage_outside_eligibility", scope: "benefits" } if uses_outside_eligibility
    warnings << { code: "company_subsidy_amount_unreliable", scope: "benefits" } if company_subsidy_amount.nil?
    warnings << { code: "confirmed_meals_unreliable", scope: "orders" } if confirmed_meals.nil?

    result = {
      period: { month: @month },
      orders: {
        confirmed_orders: confirmed.count,
        confirmed_meals:,
        pending_orders: pending.count,
        pending_meals: pending.sum(:amount)
      },
      benefits: {
        monthly_subsidized_meals: (confirmed_uses.values.sum unless missing_confirmed || invalid_confirmed_uses || mismatched_confirmed_uses),
        confirmed_meals_without_monthly_subsidy: (confirmed_meals - confirmed_uses.values.sum unless confirmed_meals.nil? || missing_confirmed || invalid_confirmed_uses || mismatched_confirmed_uses),
        monthly_pending_reserved_meals: (pending_uses.values.sum unless missing_pending || invalid_pending_uses || mismatched_pending_uses),
        known_eligible_monthly_quota_meals: known_quota,
        known_eligible_with_known_quota: quotas.size,
        monthly_quota_meals: (known_quota if complete_current_roster),
        monthly_available_meals: (known_quota - confirmed_uses.values.sum - pending_uses.values.sum if current_month && reliable_quota),
        monthly_unused_closed_meals: nil,
        company_subsidy_amount:
      },
      employees: {
        current_employees: employee_count,
        current_employees_with_orders: employees_with_orders,
        current_employees_with_confirmed_orders: consumers_with_confirmed.size,
        current_employees_without_orders: employee_count - employees_with_orders,
        eligibility: {
          eligible: eligible_ids.size,
          ineligible: eligibility.values.count(:ineligible),
          unknown: eligibility.values.count(:unknown)
        },
        known_eligible_with_confirmed_orders: eligible_with_confirmed,
        known_eligible_without_orders: eligible_without_orders,
        eligible_without_orders: (eligible_without_orders if complete_current_roster),
        participation_percent: (100.0 * eligible_with_confirmed / eligible_ids.size if complete_current_roster && eligible_ids.any?)
      },
      warnings:
    }

    result[:trends], result[:anomalies] = trends_and_anomalies(result, monthly_benefits)
    result
  end

  private

  def consumers
    @consumers ||= @company.consumers
  end

  def orders
    @orders ||= orders_for(@month)
  end

  def orders_for(month)
    Order.where(consumer_id: consumers.select(:id))
         .left_joins(:schedule)
         .where("COALESCE(orders.delivery_date, schedules.date) >= ? AND COALESCE(orders.delivery_date, schedules.date) < ?", month, month.next_month)
  end

  def company_subsidy_for(relation)
    invalid_amounts = relation.where("orders.price IS NULL OR orders.discounted_price IS NULL OR orders.price < 0 OR orders.discounted_price < 0 OR orders.discounted_price > orders.price").exists?
    return if invalid_amounts

    relation.sum("orders.price - orders.discounted_price").to_d
  end

  def confirmed_meals_for(relation)
    return if relation.where("orders.amount IS NULL OR orders.amount <= 0").exists?

    relation.sum(:amount)
  end

  def trends_and_anomalies(result, monthly_benefits)
    months = 3.downto(0).map { @month << it }
    result[:warnings] << { code: "historical_trends_from_retained_records", scope: "trends" } if months.any? { it < Date.current.beginning_of_month }
    result[:warnings] << { code: "open_month_partial", scope: "trends" } if @month == Date.current.beginning_of_month

    series = months.map do |month|
      if month == @month
        {
          month:,
          complete: month < Date.current.beginning_of_month,
          confirmed_orders: result.dig(:orders, :confirmed_orders),
          confirmed_meals: result.dig(:orders, :confirmed_meals),
          monthly_subsidized_meals: result.dig(:benefits, :monthly_subsidized_meals),
          company_subsidy_amount: result.dig(:benefits, :company_subsidy_amount)
        }
      else
        trend_snapshot(month, monthly_benefits, result[:warnings])
      end
    end

    series.each_with_index do |entry, index|
      previous = series[index - 1] if index.positive?
      entry[:changes] = %i[confirmed_orders confirmed_meals monthly_subsidized_meals company_subsidy_amount].to_h do |indicator|
        [ indicator, monthly_change(entry, previous, indicator) ]
      end
    end

    anomalies = series.flat_map do |entry|
      %i[confirmed_meals monthly_subsidized_meals].filter_map do |indicator|
        change = entry.dig(:changes, indicator)
        previous = change[:reference]
        percent = change[:percent]
        next if !entry[:complete] || previous.nil? || previous < 10 || percent.nil?
        next if (entry[indicator] - previous).abs * 100 < previous * 30

        {
          type: percent.positive? ? "increase" : "decrease",
          indicator: indicator.to_s,
          month: entry[:month],
          current_value: entry[indicator],
          reference_value: previous,
          variation_percent: percent
        }
      end
    end

    [ { months: series }, anomalies ]
  end

  def trend_snapshot(month, monthly_benefits, warnings)
    confirmed = orders_for(month).confirmed
    uses = monthly_uses_for(confirmed, monthly_benefits)
    unknown_monthly = missing_benefit_records?(confirmed) || invalid_monthly_uses?(confirmed, uses) ||
                      mismatched_benefit_uses?(confirmed)
    subsidy_amount = company_subsidy_for(confirmed)
    confirmed_meals = confirmed_meals_for(confirmed)
    warnings << { code: "trend_monthly_subsidy_unknown", scope: "trends", month: } if unknown_monthly
    warnings << { code: "trend_company_subsidy_unknown", scope: "trends", month: } if subsidy_amount.nil?
    warnings << { code: "trend_confirmed_meals_unknown", scope: "trends", month: } if confirmed_meals.nil?

    {
      month:,
      complete: month < Date.current.beginning_of_month,
      confirmed_orders: confirmed.count,
      confirmed_meals:,
      monthly_subsidized_meals: (uses.values.sum unless unknown_monthly),
      company_subsidy_amount: subsidy_amount
    }
  end

  def monthly_change(current, previous, indicator)
    reference = previous&.dig(indicator)
    return { reference:, difference: nil, percent: nil } unless previous && current[:complete] && previous[:complete]
    return { reference:, difference: nil, percent: nil } if current[indicator].nil? || reference.nil?

    difference = current[indicator] - reference
    percent = (difference.to_d * 100 / reference.to_d).round(2) unless reference.zero?
    { reference:, difference:, percent: }
  end

  def monthly_uses_for(relation, monthly_benefits)
    OrderBenefit.where(order_id: relation.select(:id), benefit_id: monthly_benefits.select(:id))
                .group(:order_id).sum(:benefit_used)
  end

  def uses_by_consumer(relation, monthly_benefits)
    OrderBenefit.joins(:order)
                .where(order_id: relation.select(:id), benefit_id: monthly_benefits.select(:id))
                .group("orders.consumer_id").sum(:benefit_used)
  end

  def missing_benefit_records?(relation)
    relation.where("orders.discounted_price < orders.price OR orders.price IS NULL OR orders.discounted_price IS NULL")
            .where.not(id: OrderBenefit.select(:order_id)).exists?
  end

  def invalid_monthly_uses?(relation, uses)
    relation.where(id: uses.keys).pluck(:id, :amount).any? do |order_id, amount|
      uses.fetch(order_id).negative? || uses.fetch(order_id) > amount.to_i
    end
  end

  def mismatched_benefit_uses?(relation)
    OrderBenefit.joins(:order, :benefit)
                .where(order_id: relation.select(:id))
                .where("benefits.consumer_id <> orders.consumer_id").exists?
  end

  def classify_eligibility(consumer_dates, monthly_benefits)
    rules = MonthlyBenefit.joins(:benefit_configuration)
                          .where(benefit_configurations: { company_id: @company.id })
                          .where(effective_from: ..@month.end_of_month)
                          .pluck(:benefit_configuration_id, :limit).to_h
    grants = monthly_benefits.where(due_date: @month.end_of_month)
                             .pluck(:id, :consumer_id, :benefit_configuration_id, :amount)
                             .group_by { it[1] }
    eligibility = {}
    quotas = {}

    consumer_dates.each do |consumer_id, onboarding_date|
      records = grants.fetch(consumer_id, [])
      if onboarding_date && onboarding_date > @month.end_of_month
        eligibility[consumer_id] = records.empty? ? :ineligible : :unknown
      elsif records.one? && rules.key?(records.first[2])
        eligibility[consumer_id] = :eligible
        limit = rules.fetch(records.first[2])
        quotas[consumer_id] = limit if limit&.positive? && records.first[3] == limit
      else
        eligibility[consumer_id] = :unknown
      end
    end

    [ eligibility, quotas ]
  end
end
