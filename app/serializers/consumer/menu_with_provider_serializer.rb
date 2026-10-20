# frozen_string_literal: true

class Consumer::MenuWithProviderSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description

  # to_f y no el decimal crudo: Alba serializa BigDecimal como string ("300.0") y
  # el tipo generado diría number.
  typelize "number | null"
  attribute :price do |menu|
    menu.price&.to_f
  end

  has_one :provider, serializer: Consumer::ProviderSerializer
end
