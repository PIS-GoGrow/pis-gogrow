# frozen_string_literal: true

# Regla de beneficio que representa un regalo de la empresa que puede ser
# usado entre determinadas fechas y con un límite
class GiftBenefit < BenefitRule
  validates :effective_from, presence: true
  validates :deadline_date, presence: true
  validates :limit, presence: true

  with_options on: :special_subsidy, allow_nil: true do
    validates :limit, numericality: { only_integer: true, greater_than: 0 }
    validates :effective_from, comparison: { greater_than_or_equal_to: -> { Date.current } }, if: :effective_from_changed?
    validates :deadline_date, comparison: { greater_than: :effective_from }, if: :effective_from
  end

  def applicable_to?(consumer, date: Date.current)
    effective_from <= date && date <= deadline_date
  end

  def benefit_limit
    limit
  end

  def benefit_deadline(consumer, date: Date.current)
    deadline_date
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
