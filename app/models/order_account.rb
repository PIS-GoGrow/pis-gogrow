# frozen_string_literal: true

class OrderAccount < ApplicationRecord
  belongs_to :account
  belongs_to :order
end
