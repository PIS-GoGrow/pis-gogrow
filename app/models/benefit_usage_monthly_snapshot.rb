# frozen_string_literal: true

require Rails.root.join("lib/ibp041/local_database_guard")

class BenefitUsageMonthlySnapshot < ApplicationRecord
  attr_accessor :correction_authorized

  enum :status, { provisional: 0, closed: 1, incomplete: 2 }

  belongs_to :company

  validates :month, presence: true, uniqueness: { scope: :company_id }
  validates :captured_at, presence: true
  validates :fictional, exclusion: { in: [ true ] },
                        unless: -> { !fictional? || Rails.env.test? || Ibp041::LocalDatabaseGuard.allowed? }
  validate :month_starts_period
  validate :nonnegative_metrics
  validate :consistent_counts
  before_update :prevent_unreviewed_closed_changes

  def participation_percent
    return if eligible_employees.nil? || eligible_employees.zero? || eligible_with_confirmed_orders.nil?

    (eligible_with_confirmed_orders.to_d * 100 / eligible_employees).round(2)
  end

  def average_confirmed_meals_per_employee
    return if employees.nil? || employees.zero? || confirmed_meals.nil?

    (confirmed_meals.to_d / employees).round(2)
  end

  def monthly_utilization_percent
    return if monthly_quota_meals.nil? || monthly_quota_meals.zero? || monthly_subsidized_meals.nil?

    (monthly_subsidized_meals.to_d * 100 / monthly_quota_meals).round(2)
  end

  private

  def month_starts_period
    errors.add(:month, :invalid) if month && month != month.beginning_of_month
  end

  def nonnegative_metrics
    %i[
      employees eligible_employees unknown_eligibility_employees employees_with_confirmed_orders
      eligible_with_confirmed_orders eligible_without_orders monthly_quota_meals monthly_subsidized_meals
      monthly_pending_reserved_meals monthly_available_meals monthly_unused_closed_meals confirmed_orders
      confirmed_meals confirmed_meals_without_monthly_subsidy pending_orders pending_meals company_subsidy_amount
    ].each do |metric|
      value = public_send(metric)
      errors.add(metric, :invalid) if value && value.negative?
    end
  end

  def consistent_counts
    if eligible_employees && eligible_with_confirmed_orders && eligible_with_confirmed_orders > eligible_employees
      errors.add(:eligible_with_confirmed_orders, :invalid)
    end
    if employees && employees_with_confirmed_orders && employees_with_confirmed_orders > employees
      errors.add(:employees_with_confirmed_orders, :invalid)
    end
    if confirmed_meals && monthly_subsidized_meals && monthly_subsidized_meals > confirmed_meals
      errors.add(:monthly_subsidized_meals, :invalid)
    end
  end

  def prevent_unreviewed_closed_changes
    throw :abort if status_in_database == "closed" && !correction_authorized
  end
end

# == Schema Information
#
# Table name: benefit_usage_monthly_snapshots
#
#  id                                      :bigint           not null, primary key
#  calculation_version                     :integer          default(1), not null
#  captured_at                             :datetime         not null
#  closed_at                               :datetime
#  company_subsidy_amount                  :decimal(14, 2)
#  confirmed_meals                         :integer
#  confirmed_meals_without_monthly_subsidy :integer
#  confirmed_orders                        :integer
#  eligible_employees                      :integer
#  eligible_with_confirmed_orders          :integer
#  eligible_without_orders                 :integer
#  employees                               :integer
#  employees_with_confirmed_orders         :integer
#  fictional                               :boolean          default(FALSE), not null
#  month                                   :date             not null
#  monthly_available_meals                 :integer
#  monthly_pending_reserved_meals          :integer
#  monthly_quota_meals                     :integer
#  monthly_subsidized_meals                :integer
#  monthly_unused_closed_meals             :integer
#  pending_meals                           :integer
#  pending_orders                          :integer
#  status                                  :integer          default(0), not null
#  unavailable_reasons                     :jsonb            not null
#  unknown_eligibility_employees           :integer
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  company_id                              :bigint           not null
#
# Indexes
#
#  index_benefit_usage_monthly_snapshots_on_company_id            (company_id)
#  index_benefit_usage_monthly_snapshots_on_company_id_and_month  (company_id,month) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
