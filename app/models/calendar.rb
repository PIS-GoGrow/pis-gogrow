# frozen_string_literal: true

# Representa todas las reglas de negocio asociadas con fechas de la aplicación.
# Por ejemplo, cuándo se pueden hacer pedidos o cuándo hay que configurar beneficios
# No es una tabla en la base de datos, es nada más una clase de Ruby.
class Calendar
  def initialize(today: Date.current)
    @today = today
  end

  # Define qué fechas debe ver el consumidor para poder hacer pedidos. Si estamos a
  # fin de semana, es la semana que viene, y si no es en esta.
  def schedule_week_range
    start_date = @today.on_weekend? ? @today.next_occurring(:monday) : @today.beginning_of_week(:monday)

    start_date..start_date.next_occurring(:friday)
  end

  # Define en qué fechas se puede hacer un pedido. Si es fin de semana, es toda la
  # semana que viene, y si no es entre hoy y el próximo viernes de esta semana
  # (hoy si ya estamos a viernes).
  def allowed_order_dates
    start_date = @today.on_weekend? ? @today.next_occurring(:monday) : @today
    end_date = start_date.friday? ? start_date : start_date.next_occurring(:friday)

    start_date..end_date
  end

  # Define en qué día de este mes se deberían asignar los beneficios mensuales para
  # el mes que viene.
  def monthly_benefit_assignment
    self.class.last_saturday @today.beginning_of_month
  end

  # Define el último día en el que se pueden configurar los beneficios para el
  # mes próximo.
  # Observar que el día en el que se asignan beneficios ya no se pueden hacer
  # configuraciones para el mes que viene, porque los beneficios para el mes que
  # viene ya se asignaron.
  def configuration_cutoff
    monthly_benefit_assignment - 1.day
  end

  # Define en qué día se aplica una configuración si se crea hoy.
  def configurable_month
    if @today <= configuration_cutoff
      @today.next_month.beginning_of_month
    else
      @today.next_month.next_month.beginning_of_month
    end
  end

  # Devuelve al último sábado del mes.
  def self.last_saturday(month_start)
    last_day = month_start.end_of_month
    last_day - ((last_day.wday - 6) % 7)
  end
end
