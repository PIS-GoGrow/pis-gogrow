# frozen_string_literal: true

class Consumer::DeliveryAddressesIndexSerializer < ApplicationSerializer
  typelize office_address: :string?
  attributes :office_address

  has_many :delivery_addresses,
           serializer: Consumer::DeliveryAddressSerializer
end
