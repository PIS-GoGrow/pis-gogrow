# frozen_string_literal: true

class Provider::OperationalSettingsShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::OperationalSettingsProviderSerializer

  typelize order_deadline_passed_today: :boolean
  attributes :order_deadline_passed_today
end
