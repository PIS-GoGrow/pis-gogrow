# frozen_string_literal: true

class Consumer::ProviderSerializer < ApplicationSerializer
  typelize_from Provider

  attributes :id, :order_deadline

  attribute :name do |provider|
    provider.user&.name
  end
  typelize name: :string
end
