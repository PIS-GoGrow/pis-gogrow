# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :owner, polymorphic: true

  has_many :payments
  has_many :order_accounts
  has_many :orders, through: :order_accounts

  before_create :correct_month

  # Mantener el mes de las cuentas como la fecha correspondiente al primer
  # día del mes en el que son válidas
  def correct_month
    self.month ||= Date.current
    self.month = self.month.beginning_of_month
  end

  # Sincroniza la deuda como la suma del precio de las órdenes asociadas
  # Si es una cuenta de consumidor, se suma el precio de las órdenes.
  # Si es de Empresa, se suma el precio descontado.
  def sync_amount!
    # TODO: falta tener en cuenta solo órdenes concretadas
    if owner_type == "Consumer"
      update amount: orders.sum(:price)
    else
      update amount: orders.sum(:discounted_price)
    end
  end
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
