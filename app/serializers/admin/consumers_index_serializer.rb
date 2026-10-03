# frozen_string_literal: true

class Admin::ConsumersIndexSerializer < ApplicationSerializer
  has_many :consumers, resource: Admin::ConsumerRowSerializer
end
