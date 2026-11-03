# frozen_string_literal: true

# Lo que la empresa le debe a cada proveedor, período por período. La cuenta con
# owner Company guarda el subsidio, que es la parte que paga GoGrow; la parte
# del empleado vive en su propia cuenta y no se muestra acá.
class Admin::PaymentsController < Admin::InertiaController
  before_action :set_payment, only: [ :destroy ]

  def index
    accounts = company.accounts.where.not(amount: ..0).preload(:payments, :invoices).order(month: :desc)
    settled, unpaid = accounts.partition { it.collection_status == "approved" }
    sums = Account.amount_and_price_sum(accounts.map(&:id))

    @accounts = serialize(unpaid, sums)
    @history = serialize(settled, sums)
    @providers = Provider.eager_load(:user).order("LOWER(users.name)")
    @total_debt = unpaid.sum(&:payable_amount).to_f
    @total_meals = unpaid.sum { sums.dig(it.id, :amount).to_i }

    # La tarjeta "Tu consumo" muestra el mes de ?month=AAAA-MM, o el actual.
    summary = AdminMonthlySummary.new(company, selected_month)
    @month = summary.month.strftime("%Y-%m")
    @current_month = Date.current.strftime("%Y-%m")
    @months = month_options(summary.months)
    @summary = { amount: summary.spending, meals: summary.meals, limit: summary.meals_limit }
    @consumption = AdminConsumptionDetail.new(company, summary.month).to_h
  end

  # El find va sobre las cuentas de la empresa y no sobre Account: pedir la de
  # otra empresa tiene que ser un 404, no una cuenta ajena. Responde JSON
  # porque el detalle se abre en un panel sobre la lista, sin cambiar de página.
  # Trae el mes entero y no solo la cuenta: el panel deja cambiar de proveedor.
  def show
    account = company.accounts.find(params[:id])

    render json: AdminConsumptionDetail.new(company, account.month).to_h
  end

  def create
    account = company.accounts.find(payment_account_id)
    unless account.provider.payment_details_complete?
      return redirect_back fallback_location: admin_payments_path, inertia: {
        errors: { receipt: [ t("activerecord.errors.models.payment.attributes.receipt.provider_payment_details_missing") ] }
      }, status: :see_other
    end

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
  rescue ActiveRecord::RecordNotUnique
    # Dos envíos simultáneos pasan la validación de Payment a la vez; el segundo
    # lo frena el índice único de la tabla.
    redirect_back fallback_location: admin_payments_path, inertia: {
      errors: { receipt: [ t("activerecord.errors.models.payment.attributes.receipt.already_under_review") ] }
    }, status: :see_other
  end

  # RR. HH. también ve los comprobantes que sus empleados le mandaron a cada
  # proveedor, desde el historial de Empleados; borrar sigue siendo solo de los
  # de la empresa.
  def receipt
    accounts = Account.where(owner: company).or(Account.where(owner: company.consumers))
    payment = Payment.where(account: accounts).find(params[:id])
    return head :not_found unless payment.receipt.attached?

    send_data(
      payment.receipt.download,
      filename: payment.receipt.filename.to_s,
      type: payment.receipt.content_type,
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
    Admin::AccountSerializer.new(accounts, params: { orders_sum: sums }).serializable_hash
  end
end
