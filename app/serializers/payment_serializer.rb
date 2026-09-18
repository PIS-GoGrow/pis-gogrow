# frozen_string_literal: true

class PaymentSerializer < ApplicationSerializer
  typelize_from Payment

  attributes :id, :status, :created_at
end
