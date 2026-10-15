# frozen_string_literal: true

# Reutiliza el AccountSerializer de "Mis pagos" del empleado: una cuenta de la
# empresa se lee igual que la de un empleado, así que las dos pantallas
# comparten el tipo Account.
class Admin::PaymentsIndexSerializer < ApplicationSerializer
  CONSUMPTION_DETAIL = "{ month: string; tab: 'pending' | 'history'; providers: Array<{ id: number; name: string; meals: number; " \
                       "subtotal: number; vat_rate: number; vat_amount: number; payable_amount: number; days: Array<{ date: string; " \
                       "orders: Array<{ id: number; consumer_name: string; avatar_url: string | null; meals: number; " \
                       "employee_amount: number; company_amount: number }> }> }> } | null"

  typelize accounts: "Account[]", history: "Account[]", total_debt: :number
  typelize current_month: "{ amount: number; meals: number; limit: number | null }"
  attributes :accounts, :history, :total_debt, :current_month

  typelize period: CONSUMPTION_DETAIL, current_period: CONSUMPTION_DETAIL
  attributes :period, :current_period

  has_many :providers, resource: ProviderSerializer
end
