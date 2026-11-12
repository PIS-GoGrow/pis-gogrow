# frozen_string_literal: true

class Provider::PaymentDetailsController < Provider::InertiaController
  def show
    @provider = Current.user.provider
    @bank_names = Provider::BANK_NAMES | [ @provider.bank_name ].compact
    @editing = !@provider.payment_details_complete? || ActiveModel::Type::Boolean.new.cast(params[:edit]) == true
  end

  def update
    provider = Current.user.provider
    provider.assign_attributes(payment_details_params)

    if provider.save(context: :payment_details)
      provider.mark_section_configured!(:payment_details)
      redirect_to provider_payment_details_path, notice: t("flash.payment_details_updated")
    else
      redirect_to provider_payment_details_path(edit: true), inertia: { errors: provider.errors }
    end
  end

  private

  def payment_details_params
    params.expect(provider: [ :bank_name, :bank_account_details, :beneficiary ])
  end
end
