# frozen_string_literal: true

# Serializa una ProviderCollectionSummary::AccountRow: la cuenta más las viandas
# que la forman, que se calculan para todas las cuentas de una vez.
class Provider::CollectionAccountSerializer < ApplicationSerializer
  typelize id: :number, owner_name: :string, meals: :number
  attributes :id, :owner_name, :meals

  typelize :number
  attribute :amount do |row|
    row.amount.to_f
  end

  typelize "'consumer' | 'company'"
  attribute :source do |row|
    row.company? ? "company" : "consumer"
  end

  # El estado del cobro es el del último comprobante, así que sigue el enum de
  # Payment; escrito a mano porque acá no hay un modelo del que inferirlo.
  typelize "'pending' | 'submitted' | 'approved' | 'rejected'"
  attribute :status, &:collection_status

  typelize :boolean
  attribute :overdue, &:overdue?

  # Formateadas en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :month do |row|
    I18n.l(row.month, format: :month_name_year)
  end

  typelize :string
  attribute :due_date do |row|
    row.due_date.strftime("%d/%m/%y")
  end

  typelize :string, nullable: true
  attribute :paid_on do |row|
    row.paid_on&.strftime("%d/%m/%y")
  end
end
