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
  # (solo hoy si ya estamos a viernes).
  def allowed_order_dates
    start_date = @today.on_weekend? ? @today.next_occurring(:monday) : @today
    end_date = start_date.friday? ? start_date : start_date.next_occurring(:friday)

    start_date..end_date
  end

  # Define en qué día de este mes se deberían asignar los beneficios mensuales para
  # el mes que viene.
  # Es igual a:
  # - El último día del mes si este cae viernes
  # - El último sábado del mes sino
  # Esto es para tener la certeza de que hasta el día que se asignen los beneficios,
  # el cliente no va a haber podido hacer pedidos para el mes que viene
  # Observar que siempre que se cumple que
  #   allowed_order_dates.include?(@today.next_month.beginning_of_month)
  # entonces también se cumple que
  #   monthly_benefit_assignment <= @today
  # Además, monthly_benefit_assignment es el mayor día de este mes que cumple esto.
  def monthly_benefit_assignment
    if @today.end_of_month.friday?
      @today.end_of_month
    else
      self.class.last_saturday @today.beginning_of_month
    end
  end

  # Define el último día de este mes en el que se pueden configurar los beneficios
  # para el mes próximo.
  # Observar que el día en el que se asignan beneficios ya no se pueden hacer
  # configuraciones para el mes que viene, porque los beneficios para el mes que
  # viene ya se asignaron.
  def configuration_cutoff
    monthly_benefit_assignment - 1.day
  end

  # Define en qué día se aplica una configuración si se crea hoy.
  # La configuración no puede aplicar para el mes que viene si pasamos
  # configuration_cutoff porque ya se asignaron los beneficios, tiene que pasar para
  # el otro
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
