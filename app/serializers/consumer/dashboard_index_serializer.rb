# frozen_string_literal: true

class Consumer::DashboardIndexSerializer < ApplicationSerializer
  attributes :week, :schedules, :benefit, :addresses

  typelize week: "{ start_date: string; end_date: string; days: Array<{ date: string; weekday: string; day: number }> }"
  typelize schedules: "Array<{ id: number; date: string; remaining: number; sold_out: boolean; menu: { id: number; name: string; description: string | null; price: number; fillings: string[]; sauces: string[]; provider_name: string; home_delivery: boolean; reviews: Array<{ id: number; description: string | null; rating: number | null; created_at: string }> } }>"
  typelize benefit: "{ limit: number; used: number; percentage: number; monthly_limit: number; monthly_used: number; monthly_remaining: number }"
  typelize addresses: "Array<{ id: string; label: string; address: string }>"
end
