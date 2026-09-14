# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :menu

  # Hay que validar que este sea el comportamiento esperado
  has_many :orders, dependent: :nullify

  def remaining_amount
    # amount representa el cupo TOTAL de esta oferta; no lo descontamos al reservar.
    # Restamos las unidades de pedidos pendientes, completados y antiguos sin estado
    # (nil). Los cancelados no ocupan cupo. El máximo con 0 evita devolver negativos.
    [ amount.to_i - orders.where(status: [ nil, :pending, :completed ]).sum(:amount), 0 ].max
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
#  amount     :integer
#  date       :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_schedules_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
