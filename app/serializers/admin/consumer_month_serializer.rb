# frozen_string_literal: true

class Admin::ConsumerMonthSerializer < ApplicationSerializer
  typelize key: :string, year: :number, amount: :number, subsidy: :number
  attributes :key, :year, :amount, :subsidy

  typelize :string
  attribute :label do |row|
    I18n.l(row.month, format: :month_name_year)
  end

  typelize "'pending' | 'submitted' | 'approved' | 'rejected' | null"
  attribute :status, &:status

  typelize "Array<{ name: string; amount: number; status: 'pending' | 'submitted' | 'approved' | 'rejected' }>"
  attribute :providers do |row|
    row.providers.map(&:to_h)
  end

  has_many :orders, resource: Admin::ConsumerOrderSerializer
end
