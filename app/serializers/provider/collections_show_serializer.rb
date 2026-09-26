# frozen_string_literal: true

class Provider::CollectionsShowSerializer < ApplicationSerializer
  has_one :account, resource: Provider::CollectionAccountSerializer
  has_many :orders, resource: Provider::CollectionOrderSerializer
  has_many :payments, resource: Provider::CollectionPaymentSerializer
end
