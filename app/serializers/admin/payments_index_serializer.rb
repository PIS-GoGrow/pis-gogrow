# frozen_string_literal: true

# Reutiliza el AccountSerializer de "Mis pagos" del empleado: una cuenta de la
# empresa se lee igual que la de un empleado, así que las dos pantallas
# comparten el tipo Account.
class Admin::PaymentsIndexSerializer < ApplicationSerializer
  typelize accounts: "Account[]", history: "Account[]", total_debt: :number
  typelize current_month: "{ amount: number; meals: number; limit: number | null }"
  attributes :accounts, :history, :total_debt, :current_month

  has_many :providers, resource: ProviderSerializer
end
