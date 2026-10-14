# frozen_string_literal: true

class Admin::DashboardIndexSerializer < ApplicationSerializer
  typelize today: :string
  attributes :today

  typelize month: :string, current_month: :string
  attributes :month, :current_month

  typelize months: "Array<{ key: string; label: string }>"
  attributes :months

  typelize summary: "{ meals: number; meals_limit: number | null; participation: number; spending: number; paid: number; pending: number; projected: number }"
  attributes :summary

  typelize payment_month: :string
  attributes :payment_month

  typelize payments: "Array<{ name: string; amount: number; status: 'pending' | 'submitted' | 'approved' | 'rejected' }>"
  attributes :payments

  has_many :debtors, resource: Admin::ConsumerRowSerializer
end
