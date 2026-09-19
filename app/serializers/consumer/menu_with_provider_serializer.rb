# frozen_string_literal: true

class Consumer::MenuWithProviderSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description, :price

  has_one :provider, serializer: Consumer::ProviderSerializer
end
