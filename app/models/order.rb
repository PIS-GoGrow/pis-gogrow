# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :consumer
  belongs_to :schedule
end
