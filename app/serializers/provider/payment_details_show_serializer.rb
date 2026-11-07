# frozen_string_literal: true

class Provider::PaymentDetailsShowSerializer < ApplicationSerializer
  typelize bank_names: "string[]"
  typelize editing: :boolean
  attributes :bank_names, :editing

  has_one :provider, serializer: Provider::PaymentDetailsProviderSerializer
end
