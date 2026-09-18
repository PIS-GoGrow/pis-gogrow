# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :owner, polymorphic: true

  # TODO: Habría que validar que los dependent: :destroy son esperables
  has_many :payments, dependent: :destroy
  has_many :order_accounts, dependent: :destroy

  has_many :orders, through: :order_accounts
  belongs_to :provider

  before_create :correct_month

  scope :current, -> { where(month: Date.current.beginning_of_month) }
  scope :pending, -> {
    where
      .missing(:payments)
      .or(
        Account.where.not(payments: { status: 0 })
      )
      .distinct
  }
  scope :history, -> {
    joins(:payments)
      .where(payments: { status: 0 })
      .distinct
  }

  def current?
    month == Date.current.beginning_of_month
  end

  def due_date
    month + 1.month + 4.days
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

  private

  # Mantener el mes de las cuentas como la fecha correspondiente al primer
  # día del mes en el que son válidas
  def correct_month
    self.month ||= Date.current
    self.month = self.month.beginning_of_month
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
