# frozen_string_literal: true

# Arma el resumen de cobros de un proveedor: cuánto vendió en el mes, cuánto le
# deben todavía, y el detalle agrupado por cliente (la empresa) y mes. Cada
# grupo junta la cuenta de la empresa, que paga el subsidio, con las de sus
# empleados, que pagan su parte.
#
# Un grupo está en el historial cuando todas sus cuentas están confirmadas;
# mientras falte algo aparece completo entre los pendientes.
#
# Los totales salen de las mismas cuentas contra las que se liquidan los pagos,
# así que validar un pago no cambia ningún monto: solo mueve el importe de un
# estado a otro.
class ProviderCollectionSummary
  # Estado que muestra el grupo de empleados: el que más atención pide.
  EMPLOYEES_STATUS_PRIORITY = %w[rejected pending submitted approved].freeze

  AccountRow = Data.define(:account, :meals) do
    delegate :id, :amount, :collection_status, :month, :due_date, to: :account

    def owner_name
      ProviderCollectionSummary.owner_name(account)
    end

    def company?
      account.owner_type == "Company"
    end

    def approved?
      collection_status == "approved"
    end

    def overdue?
      !approved? && Date.current > due_date
    end

    # La fecha del comprobante que se confirmó.
    def paid_on
      account.last_payment.created_at.to_date if approved?
    end
  end

  Group = Data.define(:client, :month, :company_row, :employee_rows, :meals) do
    def rows = [ company_row, *employee_rows ].compact

    def key = "#{client.id}-#{month.strftime('%Y-%m')}"

    def total = rows.sum(&:amount)

    def confirmed_total = rows.select(&:approved?).sum(&:amount)

    def awaiting_count = rows.count { it.collection_status.in?(%w[pending submitted]) }

    def rejected_count = rows.count { it.collection_status == "rejected" }

    def settled? = rows.all?(&:approved?)

    def employees_total = employee_rows.sum(&:amount)

    def employees_status
      statuses = employee_rows.map(&:collection_status)
      EMPLOYEES_STATUS_PRIORITY.find { it.in?(statuses) }
    end
  end

  def self.owner_name(account)
    account.owner.is_a?(Consumer) ? account.owner.user.name : account.owner.name
  end

  # La fila de una sola cuenta, para la pantalla de detalle.
  def self.row_for(account)
    meals = Account.amount_and_price_sum([ account.id ]).dig(account.id, :amount) || 0

    AccountRow.new(account:, meals:)
  end

  def initialize(provider:)
    @provider = provider
  end

  def sales
    current = accounts.select { it.month == Date.current.beginning_of_month }

    { total: amount_of(current), meals: meals_of(current) }
  end

  def outstanding
    owed = rows.reject(&:approved?).map(&:account)

    { total: amount_of(owed), meals: meals_of(owed) }
  end

  def clients
    groups.map(&:client).uniq.sort_by(&:name).map { { id: it.id, name: it.name } }
  end

  def pending = groups.reject(&:settled?)

  def history = groups.select(&:settled?)

  private

  def accounts
    @accounts ||= begin
      records = @provider.accounts.preload(:payments, :owner).to_a

      # owner es polimórfico y Company no responde a :user, así que los
      # empleados se completan aparte.
      consumers = records.map(&:owner).grep(Consumer)
      ActiveRecord::Associations::Preloader.new(records: consumers, associations: [ :user, :company ]).call if consumers.any?

      records
    end
  end

  # Unidades de cada pedido confirmado por cuenta, en una sola consulta. Los
  # pedidos cuelgan a la vez de la cuenta del empleado y de la de su empresa, así
  # que para sumar viandas de varias cuentas hay que contar cada pedido una vez.
  def order_units
    @order_units ||=
      OrderAccount.joins(:order).merge(Order.confirmed)
                  .where(account_id: accounts.map(&:id))
                  .pluck(:account_id, :order_id, "orders.amount")
                  .group_by(&:first)
                  .transform_values { |entries| entries.to_h { |_, order_id, units| [ order_id, units ] } }
  end

  def meals_of(records)
    records.map { order_units.fetch(it.id, {}) }.reduce({}, :merge).values.sum
  end

  def amount_of(records)
    records.sum { it.amount || 0 }.to_f
  end

  # Las cuentas en cero no tienen nada que cobrar (solo pedidos sin confirmar).
  def rows
    @rows ||= accounts.select { it.amount.to_d.positive? }.map { AccountRow.new(account: it, meals: meals_of([ it ])) }
  end

  def groups
    @groups ||=
      rows.group_by { [ client_of(it.account), it.month ] }
          .map { |(client, month), group_rows| build_group(client, month, group_rows) }
          .sort_by { [ -it.month.jd, it.client.name ] }
  end

  def build_group(client, month, group_rows)
    company_row, employee_rows = group_rows.partition(&:company?)

    Group.new(
      client:,
      month:,
      company_row: company_row.first,
      employee_rows: employee_rows.sort_by { it.owner_name.downcase },
      meals: meals_of(group_rows.map(&:account))
    )
  end

  def client_of(account)
    account.owner.is_a?(Consumer) ? account.owner.company : account.owner
  end
end
