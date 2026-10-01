# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :menu
  belongs_to :availability_changed_by, class_name: "User", optional: true

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

  # Se publica como mucho hasta el viernes de la semana siguiente.
  def self.maximum_publish_date
    Date.current.next_week(:monday) + 4.days
  end

  def remaining_amount
    # amount representa el cupo TOTAL de esta oferta; no lo descontamos al reservar.
    # Restamos las unidades de pedidos pendientes, confirmados y antiguos sin estado
    # (nil). Los cancelados y rechazados no ocupan cupo. El máximo con 0 evita devolver negativos.
    reserved = orders.select { |o| [ nil, "pending", "confirmed" ].include?(o.status) }
                     .sum { |o| o.amount.to_i }

    [ amount.to_i - reserved, 0 ].max
  end

  def available?(quantity: 1)
    date.present? && date >= Date.current && !order_deadline_passed? && remaining_amount >= quantity && available
  end

  def order_deadline_passed?
    date == Date.current && menu.provider.order_deadline_passed_today?
  end

  # No cancela los pedidos ya hechos sobre esta publicación: Order.reserve/#modify
  # son quienes consultan available? antes de guardar uno nuevo. Este método solo
  # persiste el cambio y quién/cuándo lo hizo, igual que Order#cancel con
  # cancelled_by/cancelled_at.
  def set_availability(available:, by:)
    update(available:, availability_changed_at: Time.current, availability_changed_by: by)
  end
end

# == Schema Information
#
# Table name: schedules
#
#  id                         :bigint           not null, primary key
#  amount                     :integer          not null
#  availability_changed_at    :datetime
#  available                  :boolean          default(TRUE), not null
#  date                       :date             not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  availability_changed_by_id :bigint
#  menu_id                    :bigint           not null
#
# Indexes
#
#  index_schedules_on_availability_changed_by_id  (availability_changed_by_id)
#  index_schedules_on_menu_id                     (menu_id)
#  index_schedules_on_menu_id_and_date            (menu_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (availability_changed_by_id => users.id)
#  fk_rails_...  (menu_id => menus.id)
#
