# frozen_string_literal: true

class Consumer::ProfilesShowSerializer < ApplicationSerializer
  attributes :benefit, :coupons

  typelize benefit: "{ percentage: number; monthly_limit: number; monthly_remaining: number; max_price: number | null; due_date: string | null } | null"
  typelize coupons: "Array<{ id: number; name: string; percentage: number; remaining: number; period: string }>"

  typelize benefit_summary: [ nullable: true ]
  has_one :benefit_summary, resource: BenefitSummarySerializer
end
