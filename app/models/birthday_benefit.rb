# frozen_string_literal: true

# Regla de beneficio que se puede usar entre el cumpleaños del consumidor
# y deadline_days días más, con un determinado límite
class BirthdayBenefit < BenefitRule
  validates :deadline_days, presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :limit, presence: true, numericality: { greater_than: 0 }

  def applicable_to?(consumer, date: Date.current)
    birthday = consumer&.birthday
    return false unless birthday

    # Probamos con el cumpleaños del año de `date` y con el del año anterior:
    # la ventana puede haber arrancado en diciembre y seguir en enero
    # (ej: cumpleaños el 31/12 y hoy es 01/01).
    [ date.year - 1, date.year ].any? do |year|
      next false if year < birthday.year

      # `advance` resuelve el 29/02 en años no bisiestos como 28/02.
      start = birthday.advance(years: year - birthday.year)
      (start..(start + deadline_days)).cover?(date)
    end
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
