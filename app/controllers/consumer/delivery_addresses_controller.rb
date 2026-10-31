# frozen_string_literal: true

class Consumer::DeliveryAddressesController < Consumer::InertiaController
  def index
    consumer = Current.user.consumer

    @office_address = consumer.company.address
    @delivery_addresses = consumer.saved_addresses.order(created_at: :desc)
  end

  def create
    delivery_address = saved_addresses.new(delivery_address_params)
    saved = management_request? || save_for_later? ? delivery_address.save : delivery_address.valid?

    if saved
      redirect_to create_redirect_path, status: :see_other
    else
      redirect_to create_redirect_path,
                  inertia: { errors: delivery_address.errors },
                  status: :see_other
    end
  end

  def update
    delivery_address = saved_addresses.find(params[:id])

    if delivery_address.update(delivery_address_params)
      redirect_to delivery_addresses_path, status: :see_other
    else
      redirect_to delivery_addresses_path,
                  inertia: { errors: delivery_address.errors },
                  status: :see_other
    end
  end

  def destroy
    saved_addresses.find(params[:id]).destroy!

    redirect_to delivery_addresses_path, status: :see_other
  end

  private

  def saved_addresses
    Current.user.consumer.saved_addresses
  end

  def save_for_later?
    ActiveModel::Type::Boolean.new.cast(
      params.dig(:delivery_address, :save_for_later)
    )
  end

  def delivery_address_params
    params.expect(delivery_address: %i[name street apartment])
  end

  def management_request?
    params[:source] == "addresses"
  end

  def create_redirect_path
    return delivery_addresses_path if management_request?

    url_from(request.referer) || dashboard_cart_path
  end
end
