# frozen_string_literal: true

class Provider::PaymentsController < Provider::InertiaController
  before_action :set_payment, only: [ :update, :receipt ]

  # Comprobantes enviados que el proveedor todavía tiene que revisar.
  def index
    payments = provider_payments.submitted
                                .with_attached_receipt
                                .includes(account: :owner)
                                .order(:created_at)

    render inertia: "provider/payments/index", props: {
      payments: Provider::PaymentSerializer.new(payments).as_json
    }
  end

  def update
    unless @payment.submitted?
      return redirect_back fallback_location: provider_payments_path,
                           alert: t("validations.payment_not_reviewable"), status: :see_other
    end

    reviewed =
      case params[:status]
      when "approved" then @payment.approve
      when "rejected" then @payment.reject_with(params[:rejection_reason].to_s.strip)
      else return head :unprocessable_entity
      end

    if reviewed
      redirect_to provider_payments_path, notice: t("flash.payment_#{@payment.status}"), status: :see_other
    else
      redirect_back fallback_location: provider_payments_path,
                    inertia: { errors: @payment.errors.to_hash }, status: :see_other
    end
  end

  # Mismo esquema que Consumer::PaymentsController#receipt, pero para el proveedor.
  def receipt
    return head :not_found unless @payment.receipt.attached?

    send_data(
      @payment.receipt.download,
      filename: @payment.receipt.filename.to_s,
      type: @payment.receipt.content_type,
      disposition: "inline"
    )
  end

  private

  # El find va sobre los pagos del proveedor: pedir el de otro tiene que ser un 404.
  def set_payment
    @payment = provider_payments.find(params[:id])
  end

  def provider_payments
    Current.user.provider.payments
  end
end
