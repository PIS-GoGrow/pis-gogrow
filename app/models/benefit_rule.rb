# frozen_string_literal: true

# De esta clase heredan todas las reglas de beneficio posibles en el sistema
class BenefitRule < ApplicationRecord
  belongs_to :benefit_configuration

  # Cada regla que herede tiene que implementar los siguientes métodos:

  # Indica si correspondería asignarle un beneficio al consumidor en la fecha dada
  # según esta regla. La respuesta debería ser true cuando la regla indica que el
  # consumidor podría llegar a tener el beneficio, sin chequear si el beneficio ya
  # fue usado (esa es la responsabilidad de la clase Benefit)
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
