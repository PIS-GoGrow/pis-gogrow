# frozen_string_literal: true

class Admin::ConsumersIndexSerializer < ApplicationSerializer
  typelize filter: "'all' | 'pending'"
  attributes :filter

  has_many :consumers, resource: Admin::ConsumerRowSerializer
end
