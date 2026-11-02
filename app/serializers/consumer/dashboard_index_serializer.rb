# frozen_string_literal: true

class Consumer::DashboardIndexSerializer < ApplicationSerializer
  attributes :week, :schedules, :benefit, :favorites, :frequent

  typelize week: "{ start_date: string; end_date: string; days: Array<{ date: string; weekday: string; day: number }> }"
  typelize schedules: "Array<{ id: number; date: string; remaining: number; sold_out: boolean; orders_closed: boolean; menu: { id: number; name: string; description: string | null; price: number; provider_id: number; saved_menu_id: number; option_groups: Array<{ id: number; name: string; options: string[]; limit: number; required: boolean }>; provider_name: string; home_delivery: boolean; rating_average: number | null; rating_count: number; reviews: Array<{ id: number; author: string | null; description: string | null; rating: number; created_at: string }> } }>"
  typelize benefit: "{ percentage: number; monthly_limit: number; monthly_used: number; monthly_remaining: number; specials: Array<{ id: number; name: string; percentage: number; remaining: number | null; due_date: string | null }>  }"

  typelize favorites: "{ menus: Array<{ id: number; name: string; description: string | null; price: number; provider_id: number; provider_name: string }>; provider_ids: number[] }"
  typelize frequent: "{ menus: Array<{ id: number; name: string; description: string | null; price: number; provider_id: number; provider_name: string }>; provider_ids: number[] }"

  has_many :providers, serializer: Consumer::ProviderSerializer
  has_many :closures, serializer: Consumer::ClosureSerializer
end
