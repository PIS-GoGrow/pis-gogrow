# frozen_string_literal: true

class AccountSerializer < ApplicationSerializer
  typelize_from Account

  attributes :id

  typelize :string?
  attribute :month do |account|
    account.month&.iso8601
  end

  # to_f y no el decimal crudo: Alba serializa BigDecimal como string y el tipo
  # generado diría number. En el cliente solo se formatea, no se opera.
  typelize :number?
  attribute :amount do |account|
    account.amount&.to_f
  end
end
