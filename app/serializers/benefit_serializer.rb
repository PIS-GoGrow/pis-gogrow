# frozen_string_literal: true

class BenefitSerializer < ApplicationSerializer
  typelize_from Benefit

  attributes :id, :amount, :description, :percentage

  typelize :string?
  attribute :due_date do |benefit|
    benefit.due_date&.iso8601
  end
end
