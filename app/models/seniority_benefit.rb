# frozen_string_literal: true

# Regla de beneficio que se puede usar sin límite a partir de que el empleado
# estuvo min_years años en la empresa
class SeniorityBenefit < BenefitRule
  validates :min_years, presence: true

  def applicable_to?(consumer, date: Date.current)
    onboarding = consumer.onboarding_date

    date >= onboarding + min_years.years
  end

  # El beneficio de antigüedad no tiene límite ni fecha límite
  def benefit_limit
    nil
  end

  def benefit_deadline(consumer, date: Date.current)
    nil
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
