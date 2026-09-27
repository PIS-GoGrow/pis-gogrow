# frozen_string_literal: true

class Provider::OperationalSettingsShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::OperationalSettingsProviderSerializer
end
