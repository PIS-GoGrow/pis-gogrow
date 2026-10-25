# frozen_string_literal: true

class Consumer::DashboardCartSerializer < ApplicationSerializer
  attributes :addresses, :benefit

  typelize benefit: "{ percentage: number; monthly_limit: number; monthly_used: number; monthly_remaining: number; specials: Array<{ id: number; name: string; percentage: number; remaining: number | null; due_date: string | null }> }"
  typelize addresses: "Array<{ id: string; label: string; address: string }>"
end
