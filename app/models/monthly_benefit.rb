# frozen_string_literal: true

# Representa el subsidio base de la empresa, que se aplica en cada mes.
# Es siempre aplicable cuando se pasó la fecha effective_from y si la compañía
# no tiene MonthlyBenefits que apliquen más tarde.
class MonthlyBenefit < BenefitRule
  belongs_to :benefit_configuration

  validates :max_price, presence: true,
    numericality: { greater_than: 0 }
  validates :limit, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :effective_from, presence: true,
    comparison: { greater_than_or_equal_to: -> { Date.current } }
  validate :unique_effective_from_per_company

  def applicable_to?(consumer, date: Date.current)
    return false if effective_from > date

    current_base_subsidy = BenefitConfiguration.base_subsidy_for(benefit_configuration.company, effective_from: date)
    current_base_subsidy&.id.in? [benefit_configuration_id, nil]
  end

  def benefit_limit
    limit
  end

  def benefit_deadline(consumer, date: Date.current)
    date.end_of_month
  end

  private

  def unique_effective_from_per_company
    existing = self.class.joins(:benefit_configuration)
      .where(effective_from: effective_from)
      .where(benefit_configurations: { company_id: benefit_configuration.company_id })
      .where.not(id: id)

    errors.add(:effective_from, "ya existe para esta empresa") if existing.exists?
  end
end

# == Schema Information
#
# Table name: benefit_rules
#
#  id                       :bigint           not null, primary key
#  deadline_date            :date
#  deadline_days            :integer
#  effective_from           :date
#  limit                    :integer
#  max_price                :decimal(10, 2)
#  min_years                :integer
#  type                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#
# Indexes
#
#  index_benefit_rules_on_benefit_configuration_id  (benefit_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#
