# frozen_string_literal: true

class Admin::ConsumersIndexSerializer < ApplicationSerializer
  attributes :query
  typelize query: :string

  has_many :consumers, resource: ConsumerSerializer
end
