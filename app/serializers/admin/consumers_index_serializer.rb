# frozen_string_literal: true

class Admin::ConsumersIndexSerializer < ApplicationSerializer
  typelize filter: "'all' | 'pending'"
  attributes :filter

  typelize month: :string, current_month: :string
  attributes :month, :current_month

  typelize months: "Array<{ key: string; label: string }>"
  attributes :months

  has_many :consumers, resource: Admin::ConsumerRowSerializer
end
