# frozen_string_literal: true

# Lo que la empresa le debe a cada proveedor, período por período. La cuenta con
# owner Company guarda el subsidio, que es la parte que paga GoGrow; la parte
# del empleado vive en su propia cuenta y no se muestra acá.
class Admin::PaymentsController < Admin::InertiaController
  def index
    accounts = company.accounts.where.not(amount: ..0).preload(:payments).order(month: :desc)
    settled, unpaid = accounts.partition { it.collection_status == "approved" }
    sums = Account.amount_and_price_sum(accounts.map(&:id))

    @accounts = serialize(unpaid, sums)
    @history = serialize(settled, sums)
    @providers = Provider.eager_load(:user).order("LOWER(users.name)")
    @total_debt = unpaid.sum { it.amount || 0 }.to_f
    @current_month = current_month_summary
  end

  # El find va sobre las cuentas de la empresa y no sobre Account: pedir la de
  # otra empresa tiene que ser un 404, no una cuenta ajena. Responde JSON
  # porque el detalle se abre en un panel sobre la lista, sin cambiar de página.
  def show
    account = company.accounts.find(params[:id])

    render json: {
      orders: SimplifiedOrderSerializer.new(account.orders.confirmed.order(:created_at)).serializable_hash,
      month: I18n.l(account.month, format: :month_year),
      amount: account.amount.to_f
    }
  end

  private

  def company
    Current.user.admin.company
  end

  # Las viandas de todas las cuentas salen de una consulta sola y viajan como
  # params, que no llegan al serializer de la página: por eso se arma acá.
  def serialize(accounts, sums)
    AccountSerializer.new(accounts, params: { orders_sum: sums }).serializable_hash
  end

  # El tope mensual de la configuración es por empleado, así que el de la
  # empresa es ese número por la cantidad de empleados.
  def current_month_summary
    current = company.accounts.current
    meals = Account.amount_and_price_sum(current.pluck(:id)).values.sum { it[:amount].to_i }
    base_subsidy = BenefitConfiguration.base_subsidy_for(company)
    limit = base_subsidy&.benefit_rules&.find_by(type: MonthlyBenefit.name)&.limit

    { amount: current.sum(:amount).to_f, meals:, limit: limit && limit * company.consumers.count }
  end
end
