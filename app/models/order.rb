# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, confirmed: 1, cancelled: 2, rejected: 3 }

  belongs_to :consumer
  belongs_to :schedule

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts

  # El corte entre ambas secciones es la fecha de entrega, no el estado: una
  # orden confirmada sigue necesitando seguimiento hasta que la vianda llega.
  # Cancelled y rejected son la excepción: ya no va a llegar ninguna vianda.
  scope :upcoming, -> {
    joins(:schedule)
      .where.not(status: [ :cancelled, :rejected ])
      .where(schedules: { date: Date.current.. })
      .order(Schedule.arel_table[:date].asc)
  }

  # Definido como el complemento de upcoming para que las dos secciones
  # particionen las órdenes: sin esto, una orden sin schedule (schedule_id es
  # nullable por el dependent: :nullify) se caería de ambas listas.
  scope :history, -> {
    where.not(id: upcoming)
      .left_joins(:schedule)
      .order(Arel.sql("schedules.date DESC NULLS LAST"))
  }

  # El subsidio no se persiste: es lo que la empresa cubre, o sea la diferencia
  # entre lo que vale la vianda y lo que termina pagando el empleado.
  def subsidy
    return if price.nil? || discounted_price.nil?

    price - discounted_price
  end
end

# == Schema Information
#
# Table name: orders
#
#  id               :bigint           not null, primary key
#  address          :string
#  amount           :integer
#  discounted_price :decimal(10, 2)
#  notes            :string
#  price            :decimal(10, 2)
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  consumer_id      :bigint           not null
#  schedule_id      :bigint
#
# Indexes
#
#  index_orders_on_consumer_id  (consumer_id)
#  index_orders_on_schedule_id  (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
