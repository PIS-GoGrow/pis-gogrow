# frozen_string_literal: true

# Resumen del beneficio de una empresa en un mes. Todo sale de las cuentas con
# owner Company de ese mes, que guardan el subsidio: lo que GoGrow les paga a
# los proveedores, con el IVA de cada cuenta (payable_amount). Un pedido cae en
# el mes de su entrega, que es como se arman las cuentas.
class AdminMonthlySummary
  ProviderPayment = Data.define(:name, :amount, :status)

  attr_reader :month

  def initialize(company, month = Date.current)
    @company = company
    @month = month.beginning_of_month
  end

  def meals = orders_sum.values.sum { it[:amount].to_i }

  # El tope de la configuración es por empleado, así que el de la empresa es
  # ese número por la cantidad de empleados. nil si ese mes no había beneficio.
  def meals_limit
    limit = BenefitConfiguration.base_subsidy_for(@company, effective_from: [ @month.end_of_month, Date.current ].min)
                                &.benefit_rules&.find_by(type: MonthlyBenefit.name)&.limit

    limit && limit * consumers_count
  end

  def participation
    return 0 if consumers_count.zero?

    participants = confirmed_orders.distinct.count(:consumer_id)
    (participants * 100.0 / consumers_count).round
  end

  def spending = amount_of(accounts)

  def paid = amount_of(accounts.select { it.collection_status == "approved" })

  def pending = amount_of(accounts.reject { it.collection_status == "approved" })

  # Lo que se sumaría al gasto si el proveedor confirma los pedidos que todavía
  # no confirmó, con el IVA de la cuenta a la que van.
  def projected
    subsidies = Order.pending
                     .joins(:order_accounts)
                     .where(order_accounts: { account_id: accounts.map(&:id) })
                     .group("order_accounts.account_id")
                     .sum("orders.price - COALESCE(orders.discounted_price, orders.price)")

    accounts.sum { Account.new(amount: subsidies.fetch(it.id, 0), vat_rate: it.vat_rate).payable_amount }.to_f
  end

  def to_h
    { meals:, meals_limit:, participation:, spending:, paid:, pending:, projected: }
  end

  # A los proveedores se les paga el mes ya cerrado: el anterior al elegido.
  def payments_month = @month.prev_month

  def payments
    @company.accounts
            .where(month: payments_month)
            .where.not(amount: ..0)
            .preload(:payments, provider: :user)
            .map { ProviderPayment.new(name: it.provider.user.name, amount: it.payable_amount.to_f, status: it.collection_status) }
            .sort_by(&:name)
  end

  # Los mismos empleados que Empleados > Pendientes: los que no saldaron el mes.
  def debtors(limit: 3)
    AdminConsumerSummary.rows_for(@company, month: @month)
                        .select { it.status.in?(%w[pending rejected submitted]) }
                        .sort_by { [ -it.amount, it.name ] }
                        .first(limit)
  end

  # Del primer mes con cuentas al actual, el más nuevo primero.
  def months
    first = [ @company.accounts.minimum(:month), @month ].compact.min
    current = Date.current.beginning_of_month

    (0..((current.year * 12 + current.month) - (first.year * 12 + first.month))).map { current << it }
  end

  private

  def accounts
    @accounts ||= @company.accounts.where(month: @month).preload(:payments).to_a
  end

  def orders_sum
    @orders_sum ||= Account.amount_and_price_sum(accounts.map(&:id))
  end

  def confirmed_orders
    Order.confirmed.joins(:order_accounts).where(order_accounts: { account_id: accounts.map(&:id) })
  end

  def consumers_count
    @consumers_count ||= @company.consumers.count
  end

  def amount_of(accounts) = accounts.sum(&:payable_amount).to_f
end
