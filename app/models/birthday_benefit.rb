# frozen_string_literal: true

class BirthdayBenefit < BenefitRule
  validates :deadline_days, presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :limit, presence: true, numericality: { greater_than: 0 }

  def applicable_to?(consumer, date: Date.current)
  	birthday = consumer.birthday
  	window = birthday..(birthday + deadline_days.days)

  	# El .map es para tener en cuenta el caso borde de que el cumpleaños es
  	# el 31 de diciembre y hoy se está a primero de enero
  	window
  	  .map { |d| d.change year: date.year }
  	  .include? date
  end

  def benefit_limit
    limit
  end

  def benefit_deadline(consumer, date: Date.current)
    (birthday + deadline_days.days).change year: date.year
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
