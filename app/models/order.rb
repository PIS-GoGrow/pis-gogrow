# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, completed: 1, canceled: 2 }, default: :pending

  belongs_to :consumer
  belongs_to :schedule

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :discounted_price, comparison: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, comparison: { greater_than_or_equal_to: 0 }, presence: true

  # Método de clase: se llama con Order.reserve y recibe argumentos con nombre.
  # consumer es el empleado, schedule la oferta y notes una nota opcional.
  def self.reserve(consumer:, schedule:, notes: nil)
    # new prepara el pedido en memoria: todavía no lo guarda.
    # Reserva una unidad, toma dirección y precio del servidor, y usa el estado
    # pending que ya está definido como valor inicial en el enum de este modelo.
    order = new(consumer: consumer, schedule: schedule, amount: 1, notes: notes,
      address: consumer.address, price: schedule.menu.price)

    # Abre una transacción y bloquea esta oferta hasta terminar la operación.
    # Otra reserva de la misma oferta espera y luego comprueba el cupo actualizado.
    schedule.with_lock do
      # available? exige una fecha válida y al menos una unidad restante.
      if schedule.available?
        # save ejecuta las validaciones del modelo y, si pasan, guarda el pedido.
        # Si alguna falla, devuelve false y deja el motivo en order.errors.
        order.save
      else
        # Asocia el error al campo de selección de oferta; no guarda el pedido.
        order.errors.add(:schedule_id, I18n.t("validations.schedule_unavailable"))
      end
    end

    # Ruby devuelve la última expresión del método: aquí, el objeto del pedido.
    # El controlador puede consultar persisted? y errors para decidir la respuesta.
    order
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
#  status           :integer
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
