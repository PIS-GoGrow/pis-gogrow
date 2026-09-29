# frozen_string_literal: true

class Consumer::DeliveryAddressesController < Consumer::InertiaController
  def create
    delivery_address = Current.user.consumer.saved_addresses.new(delivery_address_params)
    saved = save_for_later? ? delivery_address.save : delivery_address.valid?

    if saved
      redirect_to dashboard_path, status: :see_other
    else
      redirect_to dashboard_path, inertia: { errors: delivery_address.errors }, status: :see_other
    end
  end

  private

  def save_for_later?
    ActiveModel::Type::Boolean.new.cast(params.dig(:delivery_address, :save_for_later))
  end

  def delivery_address_params
    params.expect(delivery_address: [ :name, :street, :apartment ])
  end
end
