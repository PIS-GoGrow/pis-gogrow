# frozen_string_literal: true

class AccountSerializer < ApplicationSerializer
  typelize_from Account

  attributes :id, :provider_id

  # to_f y no el decimal crudo: Alba serializa BigDecimal como string y el tipo
  # generado diría number. En el cliente solo se formatea, no se opera.
  typelize :number?
  attribute :amount do |account|
    account.amount&.to_f
  end

  typelize :boolean
  attribute :current do |account|
    account.current?
  end

  typelize :string?
  attribute :month do |account|
    account.month ? I18n.l(account.month, format: :month_year) : nil
  end

  typelize :string
  attribute :due_date do |account|
    account.due_date.strftime("%d/%m/%y")
  end

  typelize :boolean
  attribute :due_date_passed do |account|
    Date.current > account.due_date
  end

  typelize :number
  attribute :orders_amount_sum do |account|
    params[:orders_sum]&.dig(account.id, :amount) || 0
  end

  typelize :number
  attribute :orders_price_sum do |account|
    params[:orders_sum]&.dig(account.id, :price) || 0
  end

  many :payments, resource: PaymentSerializer
end
