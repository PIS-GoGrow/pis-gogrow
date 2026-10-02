# frozen_string_literal: true

class Provider::OperationalSettingsProviderSerializer < ApplicationSerializer
  typelize_from Provider

  typelize :string?
  attribute :order_deadline do |provider|
    provider.order_deadline&.strftime("%H:%M")
  end
end
