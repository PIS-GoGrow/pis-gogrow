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
    [ amount.to_i - orders.where(status: [ nil, :pending, :confirmed ]).sum(:amount), 0 ].max
  end

  def available?(quantity: 1)
    date.present? && date >= Date.current && !order_deadline_passed? && remaining_amount >= quantity
  end

  def order_deadline_passed?
    deadline = menu.provider.order_deadline
    return false unless date == Date.current && deadline.present?

    Time.current >= Time.zone.local(date.year, date.month, date.day, deadline.hour, deadline.min, deadline.sec)
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
