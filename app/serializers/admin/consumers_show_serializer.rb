# frozen_string_literal: true

class Admin::ConsumersShowSerializer < ApplicationSerializer
  has_one :consumer, resource: ConsumerSerializer

  attributes :summary

  typelize summary: "{ amount: number; status: 'pending' | 'submitted' | 'approved' | 'rejected' | null; meals_used: number; meals_limit: number; providers: Array<{ name: string; meals: number }> }"

  typelize benefit_summary: [ nullable: true ]
  has_one :benefit_summary, resource: BenefitSummarySerializer
  has_many :months, resource: Admin::ConsumerMonthSerializer
end
