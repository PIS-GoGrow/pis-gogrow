# frozen_string_literal: true

class Provider::PaymentsController < Provider::InertiaController
  REJECTION_REASONS = {
    "incorrect_receipt" => "El comprobante no corresponde"
  }.freeze
  MAX_REJECTION_REASON_LENGTH = 500

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
      when "partial" then @payment.mark_partial
      when "rejected"
        rejection_reason = normalized_rejection_reason
        return head :unprocessable_entity if rejection_reason.blank? ||
                                             rejection_reason.length > MAX_REJECTION_REASON_LENGTH

        @payment.reject_with(rejection_reason)
      else return head :unprocessable_entity
      end

    if reviewed
      # Sin notice: el frontend ya confirma el resultado con su propio diálogo
      # (PaymentReviewSheet), distinto según se aprobó, quedó parcial o se rechazó.
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

  def normalized_rejection_reason
    reason_key = params[:rejection_reason].to_s
    return params[:rejection_details].to_s.strip if reason_key == "other"

    REJECTION_REASONS[reason_key]
  end
end
