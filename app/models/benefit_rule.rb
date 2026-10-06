# frozen_string_literal: true

# De esta clase heredan todas las reglas de beneficio posibles en el sistema
# que son:
# - MonthlyBenefit
# - SeniorityBenefit
# - BirthdayBenefit
# - OnboardingBenefit
# - GiftBenefit
# Más información de cada una se puede encontrar en sus archivos.
# Las reglas son combinables: un determinado beneficio podría aplicarse cuando el
# usuario está en su cumpleaños y si además tiene determinada cantidad de años en
# la empresa. MonthlyBenefit no se puede combinar con el resto.
# En esta clase se define la interfaz que cada regla debe implementar y su semántica.
class BenefitRule < ApplicationRecord
  belongs_to :benefit_configuration

  validate :monthly_benefit_exclusivity

  # Indica si correspondería asignarle un beneficio al consumidor en la fecha dada
  # según esta regla. La respuesta debería ser true cuando la regla indica que el
  # consumidor podría llegar a tener el beneficio, sin chequear si el beneficio ya
  # fue usado (esa es la responsabilidad de la clase Benefit).
  # Por ejemplo, si la regla es cumpleaños con tolerancia de uso hasta cinco días
  # después del cumpleaños y con límite de una vianda, y si ya pasaron dos días desde
  # el cumpleaños y el consumidor hizo ya su pedido para este beneficio, la función
  # devuelve true porque estamos en el rango, aunque el consumidor ya lo haya usado.
  def applicable_to?(consumer, date: Date.current)
    raise NotImplementedError, "#{self.class} debe implementar applicable_to?"
  end

  # Devuelve el límite de viandas que impone esta regla
  def benefit_limit
    raise NotImplementedError, "#{self.class} debe implementar benefit_limit"
  end

  # Devuelve hasta cuándo esta regla es válida
  def benefit_deadline(consumer, date: Date.current)
    raise NotImplementedError, "#{self.class} debe implementar benefit_deadline"
  end

  # Devuelve true si la regla indica que debería crearse un beneficio futuro en el
  # día de hoy
  # En principio solo es necesario para MonthlyBenefit, por lo que por defecto es false
  def future_applicable_to?(consumer, date: Date.current)
    false
  end

  # Igual a la anterior, indica cuándo debería caducar un beneficio futuro si se crea
  # hoy.
  def future_benefit_deadline(consumer, date: Date.current)
    benefit_deadline consumer, date
  end

  private

  def monthly_benefit_exclusivity
    return true unless benefit_configuration

    siblings = benefit_configuration.benefit_rules.where.not(id: id)

    if type == "MonthlyBenefit" && siblings.exists?
      errors.add(:base, "MonthlyBenefit no puede coexistir con otras benefit_rules")
    elsif siblings.exists?(type: "MonthlyBenefit")
      errors.add(:base, "No se puede agregar otra regla cuando ya existe MonthlyBenefit")
    end
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
