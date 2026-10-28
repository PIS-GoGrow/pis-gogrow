# frozen_string_literal: true

class Consumer::DeliveryAddressSerializer < ApplicationSerializer
  typelize_from DeliveryAddress

  attributes :id, :name, :street, :apartment

  typelize :string
  attribute :address do |delivery_address|
    delivery_address.full_address
  end
end
