# frozen_string_literal: true

# Reportes de RR. HH. para un rango de fechas. A diferencia del Inicio, que sale
# de las cuentas (con IVA), todo sale de los pedidos confirmados de los
# empleados de la empresa con entrega en el rango: pendientes, cancelados y
# rechazados no cuentan nunca.
class AdminReportsSummary
  ProviderConsumption = Data.define(:provider_id, :name, :orders_count, :meals, :company_amount)

  COMPANY_AMOUNT = Arel.sql("orders.price - COALESCE(orders.discounted_price, orders.price)")
  EMPLOYEE_AMOUNT = Arel.sql("COALESCE(orders.discounted_price, orders.price)")

  def self.first_delivery_date(company)
    Order.where(consumer_id: company.consumers.select(:id))
         .left_joins(:schedule)
         .minimum(Arel.sql("COALESCE(orders.delivery_date, schedules.date)"))
  end

  def initialize(company, range)
    @company = company
    @range = range
  end

  def employees_count
    @employees_count ||= @company.consumers.count
  end

  def participants_count
    @participants_count ||= orders.distinct.count(:consumer_id)
  end

  # Empleados con al menos un pedido confirmado en el rango sobre los empleados
  # actuales, redondeado como la Participación del Inicio.
  def adhesion
    return 0 if employees_count.zero?

    (participants_count * 100.0 / employees_count).round
  end

  def orders_count = totals[0]

  def meals = totals[1]

  def company_amount = totals[2]

  def employee_amount = totals[3]

  def by_provider
    rows = orders.group("orders.provider_id")
                 .pluck("orders.provider_id", Arel.sql("COUNT(*)"), Arel.sql("SUM(orders.amount)"), Arel.sql("SUM(#{COMPANY_AMOUNT})"))
    names = Provider.where(id: rows.map(&:first)).joins(:user).pluck(:id, "users.name").to_h

    rows.map { |id, count, meals, amount| ProviderConsumption.new(provider_id: id, name: names[id], orders_count: count, meals: meals.to_i, company_amount: amount.to_d) }
        .sort_by { [ -it.meals, I18n.transliterate(it.name.to_s).downcase ] }
  end

  def daily_consumption
    rows = orders.group(Arel.sql("COALESCE(orders.delivery_date, schedules.date)"))
                 .pluck(
                   Arel.sql("COALESCE(orders.delivery_date, schedules.date)"),
                   Arel.sql("COUNT(*)"),
                   Arel.sql("COALESCE(SUM(orders.amount), 0)"),
                   Arel.sql("COALESCE(SUM(#{COMPANY_AMOUNT}), 0)")
                 )

    rows.compact
        .reject { |date, _| date.nil? }
        .map { |date, count, meals, amount| { date: date.to_s, orders: count, meals: meals.to_i, company_amount: amount.to_f } }
        .sort_by { it[:date] }
  end

  def delivery_methods
    rows = orders.group(:delivery_method)
                 .pluck(:delivery_method, Arel.sql("COUNT(*)"), Arel.sql("COALESCE(SUM(orders.amount), 0)"))
    counts = rows.to_h { |method, count, meals| [ Order.delivery_methods.key(method) || method.to_s, { orders: count, meals: meals.to_i } ] }
    {
      office: counts["office"] || { orders: 0, meals: 0 },
      home: counts["home"] || { orders: 0, meals: 0 }
    }
  end

  private

  def orders
    AdminBenefitUsageStats.orders_delivered_between(@company, @range.first, @range.last.next_day).confirmed
  end

  def totals
    @totals ||= begin
      count, meals, company, employee = orders.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(SUM(orders.amount), 0)"),
        Arel.sql("COALESCE(SUM(#{COMPANY_AMOUNT}), 0)"),
        Arel.sql("COALESCE(SUM(#{EMPLOYEE_AMOUNT}), 0)")
      )
      [ count, meals.to_i, company.to_d, employee.to_d ]
    end
  end
end
