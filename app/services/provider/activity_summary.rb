# frozen_string_literal: true

# Resumen de la actividad de un proveedor en un rango de fechas: lo usan los
# Hallazgos y el Inicio, así que los números de las dos pantallas salen siempre
# del mismo cálculo. La fecha de un pedido es la de su entrega, igual que en el
# listado de Pedidos.
#
# Un plato es la familia del plato guardado: las variantes se cuentan con él.
class Provider::ActivitySummary
  Dish = Data.define(:id, :name, :orders_count)
  RatedDish = Data.define(:id, :name, :rating, :reviews_count)

  DELIVERY_DATE = Arel.sql("COALESCE(schedules.date, orders.delivery_date)")
  DISH_ID = Arel.sql("COALESCE(menus.base_menu_id, menus.id)")

  def self.first_delivery_date(provider)
    provider.orders.left_joins(:schedule).minimum(DELIVERY_DATE)
  end

  def initialize(provider, range)
    @provider = provider
    @range = range
  end

  def orders_count
    valid_orders.count
  end

  def dishes_count
    valid_orders.joins(schedule: :menu).distinct.count(DISH_ID)
  end

  def average_rating
    rated_reviews.average(:rating)&.round(1)&.to_f
  end

  # Por ahora ninguna pantalla los muestra: el criterio de aceptación los pide y
  # el diseño todavía no.
  def status_counts
    counts = orders.group(:status).count

    Order.statuses.keys.to_h { [ it.to_sym, counts[it] || 0 ] }
  end

  def top_dishes
    counts = valid_orders.joins(schedule: :menu).group(DISH_ID).count
    names = Menu.where(id: counts.keys).pluck(:id, :name).to_h

    counts.map { |id, count| Dish.new(id:, name: names[id], orders_count: count) }
          .sort_by { [ -it.orders_count, sort_name(it.name) ] }
          .first(5)
  end

  def top_rated_dishes
    rows = rated_reviews.group(DISH_ID).pluck(DISH_ID, Arel.sql("AVG(reviews.rating)"), Arel.sql("COUNT(*)"))
    names = Menu.where(id: rows.map(&:first)).pluck(:id, :name).to_h

    rows.map { |id, average, count| RatedDish.new(id:, name: names[id], rating: average.round(1).to_f, reviews_count: count) }
        .sort_by { [ -it.rating, -it.reviews_count, sort_name(it.name) ] }
        .first(5)
  end

  private

  def orders
    @provider.orders.left_joins(:schedule).where(DELIVERY_DATE.between(@range))
  end

  def valid_orders
    orders.where.not(status: [ :cancelled, :rejected ])
  end

  # Las reseñas no tienen fecha de entrega: cuentan el día en que se escribieron.
  # Las que no tienen puntaje no entran en ningún promedio.
  def rated_reviews
    Review.joins(:menu)
          .where(menus: { provider_id: @provider.id }, created_at: @range.first.in_time_zone..@range.last.in_time_zone.end_of_day)
          .where.not(rating: nil)
  end

  def sort_name(name)
    I18n.transliterate(name.to_s).downcase
  end
end
