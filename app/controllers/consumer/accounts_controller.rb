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
    history = params[:type] == "history" # Esto hay que cambiarlo en una historia posterior

    current_month_spending = consumer.current_month_spending
    # La suma de la deuda total se calcula en memoria en el controlador, para no hacer
    # una consulta más redundante a la base de datos.
    total_debt = accounts.sum(&:amount)

    render inertia: {
      accounts: AccountSerializer.new(accounts, params: { orders_sum: sums }).as_json,
      providers: ProviderSerializer.new(providers).as_json,
      history:,
      current_month_spending:,
      total_debt:
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
