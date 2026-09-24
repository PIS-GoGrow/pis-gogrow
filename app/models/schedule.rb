# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :menu

  MAX_AMOUNT = 2_147_483_647

  has_many :orders, dependent: :nullify

  validates :date, presence: true
  validates :amount,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_AMOUNT
            }

  validates :menu_id, uniqueness: { scope: :date }

  def remaining_amount
    # amount representa el cupo TOTAL de esta oferta; no lo descontamos al reservar.
    # Restamos las unidades de pedidos pendientes, confirmados y antiguos sin estado
    # (nil). Los cancelados y rechazados no ocupan cupo. El máximo con 0 evita devolver negativos.
    reserved = orders.select { |o| [ nil, :pending, :confirmed ].include?(o.status) }
                     .sum { |o| o.amount.to_i }

    [ amount.to_i - reserved, 0 ].max
  end

  def available?(quantity: 1)
    # && significa "y": deben cumplirse las tres condiciones para poder reservar.
    # Date.current usa la fecha de la zona horaria configurada en Rails.
    # Esta regla todavía no considera el horario límite del proveedor.
    date.present? && date >= Date.current && remaining_amount >= quantity
  end
end

# == Schema Information
#
# Table name: schedules
#
#  id         :bigint           not null, primary key
#  amount     :integer          not null
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_schedules_on_menu_id           (menu_id)
#  index_schedules_on_menu_id_and_date  (menu_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
