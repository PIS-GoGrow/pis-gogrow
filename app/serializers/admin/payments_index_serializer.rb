# frozen_string_literal: true

# Reutiliza el AccountSerializer de "Mis pagos" del empleado: una cuenta de la
# empresa se lee igual que la de un empleado, así que las dos pantallas
# comparten el tipo Account.
class Admin::PaymentsIndexSerializer < ApplicationSerializer
  CONSUMPTION_DETAIL = "{ month: string; providers: Array<{ id: number; name: string; meals: number; " \
                       "subtotal: number; vat_rate: number; vat_amount: number; payable_amount: number; days: Array<{ date: string; " \
                       "orders: Array<{ id: number; consumer_name: string; avatar_url: string | null; meals: number; " \
                       "employee_amount: number; company_amount: number }> }> }> } | null"

  typelize accounts: "Account[]", history: "Account[]", total_debt: :number, total_meals: :number
  attributes :accounts, :history, :total_debt, :total_meals

  typelize month: :string, current_month: :string
  attributes :month, :current_month

  typelize months: "Array<{ key: string; label: string }>"
  attributes :months

  typelize summary: "{ amount: number; meals: number; limit: number | null }"
  attributes :summary

  typelize consumption: CONSUMPTION_DETAIL
  attributes :consumption

  has_many :providers, resource: Admin::PaymentProviderSerializer
end
