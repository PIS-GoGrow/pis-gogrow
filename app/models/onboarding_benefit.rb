# frozen_string_literal: true

class OnboardingBenefit < BenefitRule
  validates :deadline_days, presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :limit, presence: true, numericality: { greater_than: 0 }

  def applicable_to?(consumer, date: Date.current)
    onboarding = consumer.onboarding_date
    window = onboarding..(onboarding + deadline_days.days)
    
    window.cover? date
  end

  def benefit_limit
    limit
  end

  def benefit_deadline(consumer, date: Date.current)
    onboarding + deadline_days.days
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
