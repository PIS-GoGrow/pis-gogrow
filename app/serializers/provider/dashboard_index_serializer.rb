# frozen_string_literal: true

class Provider::DashboardIndexSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::DashboardProviderSerializer
end
