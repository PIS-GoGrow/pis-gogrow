# frozen_string_literal: true

class Admin::ConsumersShowSerializer < ApplicationSerializer
  has_one :consumer, resource: ConsumerSerializer

  attributes :summary, :benefit_percentage

  typelize summary: "{ amount: number; status: 'pending' | 'submitted' | 'approved' | 'rejected' | null; meals_used: number; meals_limit: number; providers: Array<{ name: string; meals: number }> }"
  typelize benefit_percentage: "number | null"

  has_many :months, resource: Admin::ConsumerMonthSerializer
end
