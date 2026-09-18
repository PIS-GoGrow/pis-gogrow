# frozen_string_literal: true

class AccountSerializer < ApplicationSerializer
  attributes :id, :amount, :provider_id

  many :payments, resource: PaymentSerializer

  typelize :boolean
  attribute :current do |account|
    account.current?
  end

  typelize :string
  attribute :month do |account|
    I18n.l(account.month, format: :month_year)
  end

  typelize :string
  attribute :due_date do |account|
    account.due_date.strftime("%d/%m/%y")
  end

  typelize :boolean
  attribute :due_date_passed do |account|
    Date.current < account.due_date
  end

  typelize :number
  attribute :orders_placed do |account|
    account.orders.sum :amount
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id          :bigint           not null, primary key
#  amount      :decimal(10, 2)
#  month       :date
#  owner_type  :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_accounts_on_owner        (owner_type,owner_id)
#  index_accounts_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
