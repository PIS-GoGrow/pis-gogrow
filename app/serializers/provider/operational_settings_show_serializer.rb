# frozen_string_literal: true

class Provider::OperationalSettingsShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::OperationalSettingsProviderSerializer
  has_many :closures, serializer: ProviderClosureSerializer

  typelize order_deadline_passed_today: :boolean
  typelize today: :string
  attributes :order_deadline_passed_today, :today
end
