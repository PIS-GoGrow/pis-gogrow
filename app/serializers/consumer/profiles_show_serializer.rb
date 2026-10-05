# frozen_string_literal: true

class Consumer::ProfilesShowSerializer < ApplicationSerializer
  attributes :benefit

  typelize benefit: "{ percentage: number; monthly_limit: number; monthly_remaining: number; max_price: number | null; due_date: string | null } | null"
end
