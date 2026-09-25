# frozen_string_literal: true

# Serializa un ProviderCollectionSummary::Group: lo que un cliente le debe al
# proveedor por un mes, con la cuenta de la empresa y las de sus empleados.
class Provider::CollectionGroupSerializer < ApplicationSerializer
  typelize key: :string, meals: :number, awaiting_count: :number, rejected_count: :number
  attributes :key, :meals, :awaiting_count, :rejected_count

  typelize :number
  attribute :client_id do |group|
    group.client.id
  end

  typelize :string
  attribute :client_name do |group|
    group.client.name
  end

  typelize :string
  attribute :month do |group|
    I18n.l(group.month, format: :month_name_year)
  end

  typelize :number
  attribute :total do |group|
    group.total.to_f
  end

  typelize :number
  attribute :confirmed_total do |group|
    group.confirmed_total.to_f
  end

  typelize :number
  attribute :employees_total do |group|
    group.employees_total.to_f
  end

  typelize "'pending' | 'submitted' | 'approved' | 'rejected' | null"
  attribute :employees_status, &:employees_status

  typelize company: [ nullable: true ]
  has_one :company_row, key: :company, resource: Provider::CollectionAccountSerializer
  has_many :employee_rows, key: :employees, resource: Provider::CollectionAccountSerializer
end
