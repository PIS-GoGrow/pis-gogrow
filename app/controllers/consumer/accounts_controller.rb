# frozen_string_literal: true

class Consumer::AccountsController < Consumer::InertiaController
  before_action :set_account, only: [ :show ]

  def index
    consumer = Current.user.consumer

    accounts = consumer.accounts.pending.includes(:payments).order :month
    # Calculamos la cantidad total de viandas pedidas y el precio total
    # para cada cuenta. Lo hacemos acá para que esto se pueda hacer con una única
    # consulta a la bd. Si se hiciera en AccountSerializer, se necesitaría una
    # consulta por cada cuenta.
    sums = Account.amount_and_price_sum(accounts.map(&:id))

    # Ordenar los proveedores por nombre, y traernos a sus usuarios correspondientes
    # para evitar repetir la consulta para obtener su nombre.
    providers = Provider.eager_load(:user).order("LOWER(users.name)")
    history = params[:type] == "history" # Esto hay que borrarlo?
    history_accounts = consumer.accounts.history.includes(:payments).order(month: :desc)
    history_sums = Account.amount_and_price_sum(history_accounts.map(&:id))

    # La suma de la deuda total se calcula en memoria en el controlador, para no hacer
    # una consulta más redundante a la base de datos.
    total_debt = accounts.sum(&:amount)
    total_meals = sums.values.sum { it[:amount].to_i }

    current_accounts = consumer.accounts.current.pluck(:id)
    current_sums = Account.amount_and_price_sum(current_accounts).values

    current_month_debt = current_sums.reduce(0) { |acc, x| acc + x[:price] }

    current_orders = Order.confirmed
                          .joins(:order_accounts)
                          .where(order_accounts: { account_id: current_accounts })
                          .order(:created_at)

    render inertia: {
      accounts: AccountSerializer.new(accounts, params: { orders_sum: sums }).as_json,
      providers: PaymentProviderSerializer.new(providers).as_json,
      history:,
      history_accounts: AccountSerializer.new(history_accounts, params: { orders_sum: history_sums }).as_json,
      current_month_debt:,
      current_month_ordered:,
      current_month_detail: {
        orders: SimplifiedOrderSerializer.new(current_orders).as_json,
        month: I18n.l(Date.current, format: :month_year),
        amount: current_month_debt
      },
      total_debt:,
      total_meals:,
      benefit_used: consumer.monthly_benefit_used_this_month,
      benefit_available: consumer.monthly_benefit_available
    }
  end

  # Este endpoint solo maneja JSON (no se accede directamente, sino que se
  # usa para darle datos al frontend)
  def show
    orders = @account.orders.confirmed.order :created_at
    month = I18n.l(@account.month, format: :month_year)
    amount = @account.amount

    render json: {
      orders: SimplifiedOrderSerializer.new(orders).as_json,
      month:,
      amount:
    }
  end

  private

  def set_account
    @account = Current.user.consumer.accounts.find(params[:id])
  end
end
