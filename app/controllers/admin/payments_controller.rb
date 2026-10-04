# frozen_string_literal: true

# Lo que la empresa le debe a cada proveedor, período por período. La cuenta con
# owner Company guarda el subsidio, que es la parte que paga GoGrow; la parte
# del empleado vive en su propia cuenta y no se muestra acá.
class Admin::PaymentsController < Admin::InertiaController
  before_action :set_payment, only: [ :destroy, :receipt ]

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

  def create
    account = company.accounts.find(payment_account_id)
    payment = account.payments.build(
      provider: account.provider,
      receipt: payment_params[:receipt],
      status: :submitted
    )

    if payment.save
      redirect_back fallback_location: admin_payments_path, status: :see_other
    else
      redirect_back fallback_location: admin_payments_path,
                    inertia: { errors: payment.errors.to_hash }, status: :see_other
    end
  end

  def receipt
    return head :not_found unless @payment.receipt.attached?

    send_data(
      @payment.receipt.download,
      filename: @payment.receipt.filename.to_s,
      type: @payment.receipt.content_type,
      disposition: "inline"
    )
  end

  def destroy
    unless @payment.submitted? || @payment.rejected?
      return redirect_back fallback_location: admin_payments_path,
                           alert: t("validations.payment_not_removable"), status: :see_other
    end

    @payment.destroy!

    redirect_back fallback_location: admin_payments_path,
                  notice: t("flash.payment_receipt_removed"), status: :see_other
  end

  private

  def company
    Current.user.admin.company
  end

  def set_payment
    @payment = Payment.where(account: company.accounts).find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:receipt)
  end

  def payment_account_id
    params.require(:payment).fetch(:account_id)
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
