# frozen_string_literal: true

class Consumer::PaymentsController < Consumer::InertiaController
  before_action :set_payment, only: :update

  def update
    if @payment.approved?
      return redirect_back fallback_location: dashboard_path, inertia: {
        errors: { receipt: [ t("validations.payment_closed") ] }
      }, status: :see_other
    end

    @payment.assign_attributes(payment_params)
    @payment.status = :submitted

    if @payment.save
      redirect_back fallback_location: dashboard_path, notice: t("flash.payment_receipt_submitted"), status: :see_other
    else
      redirect_back fallback_location: dashboard_path, inertia: { errors: @payment.errors.to_hash }, status: :see_other
    end
  end

  private

  def set_payment
    @payment = consumer_payments.find(params[:id])
  end

  def consumer_payments
    Payment.where(account: Current.user.consumer.accounts).where.not(provider_id: nil)
  end

  def payment_params
    params.fetch(:payment, {}).permit(:receipt)
  end
end
