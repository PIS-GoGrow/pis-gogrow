# frozen_string_literal: true

class Admin::ConsumersShowSerializer < ApplicationSerializer
  has_one :consumer, resource: ConsumerSerializer
  has_many :orders, resource: OrderSerializer
  has_many :benefits, resource: BenefitSerializer
  has_many :debts, resource: AccountSerializer
  has_many :payments, resource: PaymentSerializer
end
