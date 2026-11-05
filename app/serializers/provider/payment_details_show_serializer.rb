# frozen_string_literal: true

class Provider::PaymentDetailsShowSerializer < ApplicationSerializer
  typelize bank_names: "string[]"
  attributes :bank_names

  typelize :boolean
  attribute :editing do |view_assigns|
    !!view_assigns[:editing]
  end

  has_one :provider, serializer: Provider::PaymentDetailsProviderSerializer
end
