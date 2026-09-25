# frozen_string_literal: true

class Provider::DashboardProviderSerializer < ApplicationSerializer
  typelize_from Provider

  typelize :string?
  attribute :order_deadline do |provider|
    provider.order_deadline&.strftime("%H:%M")
  end
end
