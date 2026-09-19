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
    left_outer_joins(:payments)
      .where("(payments.id IS NULL OR payments.status != ?)", 0)
      .where.not(amount: ..0)
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
    # TODO: Habría que validar que se tengan solo en cuenta las órdenes confirmadas
    if owner_type == "Consumer"
      update amount: orders.confirmed.sum(:price)
    else
      update amount: orders.confirmed.sum(:discounted_price)
    end
  end

  # Acepta un arreglo de ids de cuentas.
  # Devuelve un hash que agrupa por id de cuenta el monto total de deuda
  # y la cantidad de viandas pedidas, teniendo en cuenta órdenes confirmadas.
  # Esto se hace en una única consulta, sin importar la cantidad de
  # cuentas u órdenes.
  def self.amount_and_price_sum(account_ids)
    # results es un arreglo, que para cada cuenta contiene un arreglo de la
    # forma
    #   [id_cuenta, suma_montos, suma_precios]
    results =
      Order.joins(:order_accounts)
           .confirmed
           .where(order_accounts: { account_id: account_ids })
           .group("order_accounts.account_id")
           .pluck(
             Arel.sql("order_accounts.account_id"),
             Arel.sql("SUM(orders.amount)"),
             Arel.sql("SUM(orders.price)")
           )

    # Devolvemos el arreglo, pero convertido a un hash de la forma:
    #   {id_cuenta: {amount: suma_montos, price: suma_precios}, ...}
    results.each_with_object({}) do |(account_id, amount_sum, price_sum), hash|
      hash[account_id] = { amount: amount_sum, price: price_sum }
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
