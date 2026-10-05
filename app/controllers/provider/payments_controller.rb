# frozen_string_literal: true

class Provider::PaymentsController < Provider::InertiaController
  before_action :set_payment, only: [ :update, :receipt ]

  def update
    unless @payment.submitted?
      return redirect_back fallback_location: provider_collections_path,
                           alert: t("validations.payment_not_reviewable"), status: :see_other
    end

    if params[:status] == "approved" && @payment.account.current?
      return redirect_back fallback_location: provider_collections_path,
                           alert: t("validations.payment_current_account"), status: :see_other
    end

    reviewed =
      case params[:status]
      when "approved" then @payment.approve
      when "rejected" then @payment.reject_with(params[:rejection_reason].to_s.strip)
      else return head :unprocessable_entity
      end

    if reviewed
      # Sin notice: el frontend ya confirma el resultado con su propio diálogo
      # (PaymentReviewSheet), distinto según se aprobó, se rechazó por pago
      # parcial o por otro motivo.
      redirect_to provider_collections_path, status: :see_other
    else
      redirect_back fallback_location: provider_collections_path,
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
