# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :owner, polymorphic: true
end
