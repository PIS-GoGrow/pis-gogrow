# frozen_string_literal: true

class Admin::ReportsIndexSerializer < ApplicationSerializer
  attributes :from,
    :to,
    :default_from,
    :default_to,
    :min,
    :max,
    :month_label,
    :presets,
    :summary,
    :providers

  typelize from: :string
  typelize to: :string
  typelize default_from: :string
  typelize default_to: :string
  typelize min: :string
  typelize max: :string
  typelize month_label: :string?
  typelize presets: "Array<{ key: 'today' | 'yesterday' | 'this_week' | 'this_month' | 'last_month'; from: string; to: string }>"
  typelize summary: "{ adhesion: number; participants: number; employees: number; orders: number; meals: number; company_amount: number; employee_amount: number }"
  typelize providers: "Array<{ id: number | null; name: string | null; orders: number; meals: number; company_amount: number }>"
end
