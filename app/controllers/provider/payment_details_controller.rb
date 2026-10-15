# frozen_string_literal: true

class Provider::PaymentDetailsController < Provider::InertiaController
  def show
    @provider = Current.user.provider
  end

  def update
    provider = Current.user.provider
    provider.assign_attributes(payment_details_params)

    if provider.save(context: :payment_details)
      redirect_to provider_payment_details_path, notice: t("flash.payment_details_updated")
    else
      redirect_to provider_payment_details_path, inertia: { errors: provider.errors }
    end
  end

  private

  def payment_details_params
    params.expect(provider: [ :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id ])
  end
end
