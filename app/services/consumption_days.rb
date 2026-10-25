# frozen_string_literal: true

# Pedidos agrupados por día de entrega, del más nuevo al más viejo, y dentro de
# cada día por nombre del empleado. Lo comparten el detalle de ventas del
# proveedor y el detalle del consumo de RR. HH.; cada uno arma sus filas con el
# bloque. Los pedidos tienen que venir con schedule y consumer: :user cargados.
class ConsumptionDays
  def self.call(orders, &row)
    orders.group_by { it.schedule.date }
          .sort_by { |date, _| -date.jd }
          .map do |date, day_orders|
      {
        date: DateFormat.short(date),
        orders: day_orders.sort_by { it.consumer.user.name.downcase }.map(&row)
      }
    end
  end
end
