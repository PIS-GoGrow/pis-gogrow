# frozen_string_literal: true

require "csv"

# Arma el archivo con los pedidos que el proveedor está viendo en Pedidos. Los
# filtros repiten filterOrders y searchableText (lib/provider-orders.ts): si
# cambia uno, tiene que cambiar el otro, o el archivo deja de coincidir con la
# pantalla.
class Provider::OrdersExport
  COLUMNS = %i[code delivery_date time status consumer company dish options amount delivery_method address notes price].freeze

  def initialize(orders, provider:, period:, status: nil, delivery: nil, search: nil)
    @all_orders = orders
    @provider = provider
    @period = period
    @status = status.to_s.presence_in(%w[pending confirmed])
    @delivery = delivery.to_s.presence_in(Order.delivery_methods.keys)
    @words = normalize(search.to_s).split(/[[:space:]]+/).reject(&:empty?)
  end

  def orders
    @orders ||= @all_orders.select { visible?(it) }
  end

  # El BOM y el punto y coma son para que Excel en español lo abra en columnas
  # y con las tildes bien.
  def to_csv
    "\uFEFF" + CSV.generate(col_sep: ";") do |csv|
      csv << COLUMNS.map { I18n.t("exports.provider_orders.columns.#{it}") }
      orders.each { csv << row(it) }
      csv << total_row
    end
  end

  def filename
    dates = orders.filter_map(&:delivery_date).minmax
    range = "#{dates.first.iso8601}_al_#{dates.last.iso8601}" if dates.first
    period = @period == :history ? "historial" : "proximos"
    generated = Time.current.strftime("%Y-%m-%d_%H%M")

    [ "pedidos", @provider.user.name.parameterize, period, range, "generado", generated ].compact.join("_") + ".csv"
  end

  private

  def visible?(order)
    return false if @status && order.status != @status
    return false if @delivery && order.delivery_method != @delivery
    return true if @words.empty?

    text = normalize(searchable_text(order).compact.join(" "))
    @words.all? { text.include?(it) }
  end

  def searchable_text(order)
    [
      order.consumer.user.name,
      order.consumer.company&.name,
      order.menu_name,
      address(order),
      order.notes,
      code(order),
      status_label(order),
      delivery_label(order)
    ]
  end

  def normalize(text)
    text.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase
  end

  def row(order)
    [
      code(order),
      order.delivery_date&.strftime("%d/%m/%Y"),
      order.created_at.strftime("%H:%M"),
      status_label(order),
      cell(order.consumer.user.name),
      cell(order.consumer.company&.name),
      cell(order.menu_name),
      cell(options(order)),
      order.amount,
      delivery_label(order),
      cell(address(order)),
      cell(order.notes),
      money(order.price)
    ]
  end

  def total_row
    cells = Array.new(COLUMNS.size)
    cells[0] = I18n.t("exports.provider_orders.total")
    cells[COLUMNS.index(:amount)] = orders.sum { it.amount.to_i }
    cells[COLUMNS.index(:price)] = money(orders.sum { it.price.to_d })
    cells
  end

  def options(order)
    Array(order.selected_options).map { "#{it["name"]}: #{Array(it["values"]).join(", ")}" }.join("; ").presence
  end

  def address(order)
    order.address.presence || order.consumer.address
  end

  def code(order)
    I18n.t("pages.provider_orders.index.code", id: order.id)
  end

  def status_label(order)
    I18n.t("pages.provider_orders.statuses.#{order.status}")
  end

  def delivery_label(order)
    I18n.t("pages.provider_orders.index.delivery_methods.#{order.delivery_method}")
  end

  def money(amount)
    format("%.2f", amount.to_d).tr(".", ",")
  end

  # Lo escriben los empleados: sin esto, unas notas que empiezan con "=" se
  # abren en Excel como una fórmula.
  def cell(value)
    value.to_s.start_with?("=", "+", "-", "@") ? "'#{value}" : value
  end
end
