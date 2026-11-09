# frozen_string_literal: true

class Provider::PaymentDetailsShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::PaymentDetailsProviderSerializer
end
