# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :owner, polymorphic: true

  has_many :payments, dependent: :destroy
  has_many :order_accounts, dependent: :destroy
  has_many :orders, through: :order_accounts

  # Deuda pendiente: cuentas que todavía no tienen ningún pago acreditado.
  scope :pending, -> {
    where.not(id: joins(:payments).merge(Payment.paid).select(:id))
  }
end

# == Schema Information
#
# Table name: accounts
#
#  id         :bigint           not null, primary key
#  amount     :decimal(10, 2)
#  month      :date
#  owner_type :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint           not null
#
# Indexes
#
#  index_accounts_on_owner  (owner_type,owner_id)
#
