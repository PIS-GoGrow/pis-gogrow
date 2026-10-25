# frozen_string_literal: true

class Provider::DeliveriesShowSerializer < ApplicationSerializer
  has_one :provider, serializer: ProviderSerializer

  typelize deliveries_configured: :boolean
  attributes :deliveries_configured
end
