# frozen_string_literal: true

# Arma el archivo con los pedidos que el proveedor está viendo en Pedidos. Los
# filtros repiten filterOrders y searchableText (lib/provider-orders.ts): si
# cambia uno, tiene que cambiar el otro, o el archivo deja de coincidir con la
# pantalla.
class Provider::OrdersExport
  COLUMNS = %i[code delivery_date time status consumer company dish options amount delivery_method address notes price].freeze
  # Los textos van siempre como :string: lo que escriben los empleados nunca se
  # tiene que abrir como una fórmula.
  TYPES = %i[string date string string string string string string integer string string string float].freeze

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

  def to_xlsx
    package = Axlsx::Package.new
    styles = package.workbook.styles
    bold = styles.add_style(b: true)
    date = styles.add_style(format_code: "dd/mm/yyyy")
    money = styles.add_style(format_code: "#,##0.00")
    total_money = styles.add_style(b: true, format_code: "#,##0.00")
    row_styles = COLUMNS.map { { delivery_date: date, price: money }[it] }
    total_styles = COLUMNS.map { it == :price ? total_money : bold }

    package.workbook.add_worksheet(name: "Pedidos", escape_formulas: true) do |sheet|
      sheet.add_row COLUMNS.map { I18n.t("exports.provider_orders.columns.#{it}") }, style: bold
      orders.each { sheet.add_row row(it), types: TYPES, style: row_styles }
      sheet.add_row total_row, types: TYPES, style: total_styles
      sheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = 1
        pane.top_left_cell = "A2"
        pane.active_pane = :bottom_left
      end
    end

    package.to_stream.read
  end

  def filename
    dates = orders.filter_map(&:delivery_date).minmax
    range = "#{dates.first.iso8601}_al_#{dates.last.iso8601}" if dates.first
    period = @period == :history ? "historial" : "proximos"
    generated = Time.current.strftime("%Y-%m-%d_%H%M")

    [ "pedidos", @provider.user.name.parameterize, period, range, "generado", generated ].compact.join("_") + ".xlsx"
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
      order.delivery_date,
      order.created_at.strftime("%H:%M"),
      status_label(order),
      order.consumer.user.name,
      order.consumer.company&.name,
      order.menu_name,
      options(order),
      order.amount,
      delivery_label(order),
      address(order),
      order.notes,
      order.price
    ]
  end

  def total_row
    cells = Array.new(COLUMNS.size)
    cells[0] = I18n.t("exports.provider_orders.total")
    cells[COLUMNS.index(:amount)] = orders.sum { it.amount.to_i }
    cells[COLUMNS.index(:price)] = orders.sum { it.price.to_d }
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
end
