# frozen_string_literal: true

class Provider::DeliveriesController < Provider::InertiaController
  before_action :set_provider

  def show
  end

  def update
    if @provider.update(params.permit(:home_delivery))
      redirect_to provider_deliveries_path, notice: t("flash.deliveries_updated")
    else
      redirect_to provider_deliveries_path, inertia: { errors: @provider.errors }
    end
  end

  private

  def set_provider
    @provider = Current.user.provider
  end
end
