# frozen_string_literal: true

class BenefitSummarySerializer < ApplicationSerializer
  typelize total: :number, base: :number
  attributes :total, :base

  typelize "Array<{ name: string; percentage: number }>"
  attribute :specials, &:specials
end
