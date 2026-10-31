# frozen_string_literal: true

class Admin::ConsumersShowSerializer < ApplicationSerializer
  has_one :consumer, resource: ConsumerSerializer

  attributes :summary, :debt_reminder

  typelize summary: "{ amount: number; status: 'pending' | 'submitted' | 'approved' | 'rejected' | 'partial' | null; meals_used: number; meals_limit: number; providers: Array<{ name: string; meals: number }> }"
  typelize debt_reminder: "{ eligible: boolean; amount: number; remaining: number; next_available_at: string | null; blocked_reason: string | null }"

  typelize benefit_summary: [ nullable: true ]
  has_one :benefit_summary, resource: BenefitSummarySerializer
  has_many :months, resource: Admin::ConsumerMonthSerializer
end
