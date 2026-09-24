# frozen_string_literal: true

class Consumer::PaymentsController < Consumer::InertiaController
  before_action :set_payment, only: :update

  def create
    # La cuenta se busca dentro de las cuentas del consumidor autenticado. Esto
    # evita que un account_id enviado desde el navegador cree pagos para otro empleado.
    account = consumer_accounts.find(payment_account_id)
    @payment = account.payments.build(
      provider: account.provider,
      receipt: payment_params[:receipt],
      status: :submitted
    )

    persist_payment
  end

  def update
    if @payment.approved?
      return redirect_back fallback_location: dashboard_path, inertia: {
        errors: { receipt: [ t("validations.payment_closed") ] }
      }, status: :see_other
    end

    # Active Storage reemplaza el comprobante anterior, manteniendo el mismo
    # Payment y, por lo tanto, su asociación original con Account.
    @payment.assign_attributes(receipt: payment_params[:receipt])
    @payment.status = :submitted

    persist_payment
  end

  private

  def set_payment
    @payment = consumer_payments.find(params[:id])
  end

  def consumer_payments
    Payment.where(account: consumer_accounts)
  end

  def consumer_accounts
    # El provider de la cuenta determina quién debe validar el comprobante.
    Current.user.consumer.accounts.where.not(provider_id: nil)
  end

  def payment_params
    params.require(:payment).permit(:receipt)
  end

  def payment_account_id
    params.require(:payment).fetch(:account_id)
  end

  def persist_payment
    # Payment valida tipo, tamaño y presencia del adjunto antes de impactar la BD.
    if @payment.save
      redirect_back fallback_location: accounts_path, notice: t("flash.payment_receipt_submitted"), status: :see_other
    else
      redirect_back fallback_location: accounts_path, inertia: { errors: @payment.errors.to_hash }, status: :see_other
    end
  end
end
